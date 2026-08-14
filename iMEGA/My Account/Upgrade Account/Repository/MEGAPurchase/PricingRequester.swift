import Foundation
import MEGADomain

/// Bridges `MEGAPurchase`'s pricing delegate callbacks into an `async` call, so callers can start a
/// pricing request, or join the one already in flight and suspend until the purchasable products have finished loading.
///
/// `MEGAPurchase.requestPricing` is fire-and-forget, and loads the products in two legs:
///    1. it asks the SDK for the plans (`getPricing`), and once those land
///    2. it turns the returned iOS product identifiers into an `SKProductsRequest`, asking StoreKit for the `SKProduct`s and keep them in `MEGAPurchase.products`.
/// The outcome is broadcast to `MEGAPurchasePricingDelegate`:
///   * `pricingsReady`: the App Store products arrived and the catalogue is populated.
///   * `pricingsFailed`: the request will never become ready: payments are disabled on the device, the
///     API pricing request failed, or the App Store products request failed.
///
/// This PricingRequester tracks the state of the single shared request and holds the suspended callers:
///   * the first caller flips the state to `.inFlight` and calls into `MEGAPurchase`.
///   * later callers join that request rather than starting a second one, and whichever callback lands first resume everyone at once.
///   * `cancel()` stops that request and throws its state away, so the next caller starts a new one. It is called
///     when the products stop being valid, i.e. on logout, where `MEGAPurchase.removeAllProducts` empties the catalogue.
///
/// After PricingRequester.requestPricing return, MEGAPurchase.products are available for reading
final class PricingRequester: NSObject, @unchecked Sendable {
    /// How a pricing request ended, from a caller's point of view.
    private enum Outcome {
        /// The request finished. Whether it produced products or failed, there is nothing left to wait for.
        case completed
        /// The request was cancelled, either through `cancel()` or by the calling task, so there is nothing worth waiting for any more.
        case cancelled
    }

    private enum PricingRequestState: Sendable {
        /// Nothing has been requested yet, or the last request was cancelled.
        case idle
        /// A request is in flight. Callers wait for it instead of starting a second one.
        case inFlight
        /// The products are loaded, so callers resume without waiting.
        case succeeded
        /// The last request failed. The next caller retries it.
        case failed

        var shouldStartNewRequest: Bool {
            switch self {
            case .idle, .failed:
                true
            case .inFlight, .succeeded:
                false
            }
        }
    }
    
    /// Releases one suspended caller with the outcome it waited for.
    private typealias Resume = @Sendable (Outcome) -> Void

    /// Everyone currently suspended on the in-flight request.
    private var pendingCallers: [UUID: Resume] = [:]
    private var currentRequestState: PricingRequestState = .idle
    private let lock = NSLock()
    private let purchase: MEGAPurchase
    static let shared = PricingRequester()

    /// Allow tests to inject mock MEGAPurchase
    init(purchase: MEGAPurchase = MEGAPurchase.sharedInstance()) {
        self.purchase = purchase
        super.init()
        purchase.addPricingsDelegate(self)
    }

    /// Only used for unit tests.
    /// This logic is critical and concurrency sensitive, so it is added for better tests
    var pendingCallerCount: Int {
        lock.withLock { pendingCallers.count }
    }

    // MARK: - Private

    private func requestPricing(forceRefresh: Bool) async throws {
        let shouldStartNewRequest = lock.withLock {
            let shouldStartNewRequest = if forceRefresh {
                currentRequestState != .inFlight
            } else {
                currentRequestState.shouldStartNewRequest
            }
            // Only move to `.inFlight` when a request is actually started.
            if shouldStartNewRequest {
                currentRequestState = .inFlight
            }
            return shouldStartNewRequest
        }
        if shouldStartNewRequest {
            purchase.requestPricing()
        }

        try await wait()
    }
    
    /// Suspends until the pricing request this caller joined reports an outcome.
    ///
    /// Cancellation is covered at three points, because the caller can be cancelled before, during,
    /// or after it is queued: `checkCancellation` before queueing, `isCancelled` right after, and
    /// `onCancel` while suspended.
    private func wait() async throws {
        let id = UUID()

        /// Uses `withTaskCancellationHandler` to respond immediately when the calling task is cancelled.
        /// On cancellation, resumes the pending caller with `CancellationError` and removes it from `pendingCallers`.
        try await withTaskCancellationHandler {
            try Task.checkCancellation() // checkCancellation` before queueing
            try await withCheckedThrowingContinuation { continuation in
                addPendingCaller(id: id) { outcome in
                    switch outcome {
                    case .completed:
                        continuation.resume()
                    case .cancelled:
                        // Either the products this wait was for no longer exist, or the caller
                        // walked away. Abandon the work instead of resuming into an empty
                        // catalogue — callers already treat cancellation as "stop quietly".
                        continuation.resume(throwing: CancellationError())
                    }
                }

                // A cancellation landing after `checkCancellation` but before the caller is queued
                // runs `onCancel` while `pendingCallers` is still empty, so its `cancel(id:)` has
                // nothing to remove and no callback will ever resolve this caller. Re-check so that
                // caller is not left waiting.
                if Task.isCancelled { cancel(id: id) }
            }
        } onCancel: {
            cancel(id: id)
        }
    }

    /// Queues a caller until the in-flight request finishes, or resolves it straight away when there is nothing to wait for.
    private func addPendingCaller(id: UUID, resume: @escaping Resume) {
        let outcome: Outcome? = lock.withLock {
            switch currentRequestState {
            case .idle:
                return .cancelled
            case .inFlight:
                pendingCallers[id] = resume
                return nil
            case .succeeded, .failed:
                return .completed
            }
        }

        if let outcome {
            resume(outcome)
        }
    }

    /// Records the outcome of the in-flight request and releases everyone waiting on it.
    ///
    /// An outcome is only recorded while the state is still `.inFlight`.
    /// Recording it anyway would leave `.succeeded` behind, and the next caller, the first one after
    /// logging back in, would skip the reload and read the empty products.
    ///
    /// The stale request may still update the cached products for the previously signed-in account.
    /// This is harmless because the cache is cleared when a new pricing request starts after the user logs in again.
    private func complete(success: Bool) {
        let callersToResume = lock.withLock {
            guard currentRequestState == .inFlight else { return [Resume]() }
            currentRequestState = success ? .succeeded : .failed
            defer { pendingCallers.removeAll() }
            return Array(pendingCallers.values)
        }

        callersToResume.forEach { $0(.completed) }
    }

    private func cancel(id: UUID) {
        let resume = lock.withLock { pendingCallers.removeValue(forKey: id) }
        resume?(.cancelled)
    }
}

// MARK: - PricingRequesting

extension PricingRequester: PricingRequesting {
    /// Starts a request only when there is nothing worth joining, then waits with everyone else.
    func requestPricing() async throws {
        try await requestPricing(forceRefresh: false)
    }

    /// Drops a completed request and loads the products again.
    ///
    /// Only a completed request is forgotten. One still in flight is loading the current products already,
    /// so this joins it rather than restarting it
    func refreshPricing() async throws {
        try await requestPricing(forceRefresh: true)
    }

    /// Stops the in-flight request and drops back to `.idle`, so the next caller starts a new one.
    func cancel() {
        let (hadInFlightRequest, callersToResume) = lock.withLock {
            let hadInFlightRequest = currentRequestState == .inFlight
            currentRequestState = .idle
            defer { pendingCallers.removeAll() }
            return (hadInFlightRequest, Array(pendingCallers.values))
        }

        if hadInFlightRequest {
            purchase.cancelPricingRequest()
        }

        callersToResume.forEach { $0(.cancelled) }
    }
}

// MARK: - MEGAPurchasePricingDelegate

extension PricingRequester: MEGAPurchasePricingDelegate {
    func pricingsReady() {
        complete(success: true)
    }

    func pricingsFailed() {
        complete(success: false)
    }
}
