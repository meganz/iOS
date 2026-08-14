import Foundation
@testable import MEGA
import Testing

/// `.timeLimit` is a hang backstop, not a performance assertion: a lost resume in the requester shows
/// up as a test that never finishes. One minute is the finest granularity `TimeLimitTrait` offers, and
/// the trait cascades to every test in the suite.
@Suite("PricingRequester", .timeLimit(.minutes(1)))
struct PricingRequesterTests {

    // MARK: - A single request

    /// The mock answers synchronously inside `requestPricing()`, so the outcome is recorded before the
    /// caller reaches `addPendingCaller` — this covers resolving from the recorded state, not the queue.
    /// `queuedCallersResumeWhenTheRequestFails` covers the queued path.
    @Test("resumes once the products are ready")
    func resumesWhenPricingsReady() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .ready)

        try await sut.requestPricing()

        #expect(purchase.requestPricingCallCount == 1)
        #expect(sut.pendingCallerCount == 0)
    }

    /// A failed request has to release its callers too, or the upgrade screen waits forever on a
    /// catalogue that is never coming.
    @Test("resumes when the request fails")
    func resumesWhenPricingsFailed() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .failed)

        try await sut.requestPricing()

        #expect(purchase.requestPricingCallCount == 1)
        #expect(sut.pendingCallerCount == 0)
    }

    @Test("suspends until the products are delivered")
    func suspendsUntilPricingsAreDelivered() async throws {
        let (sut, purchase) = makeSUT()
        let task = Task { try await sut.requestPricing() }

        // A caller still sitting in `pendingCallers` provably has not been resumed, so this is a fact
        // about the requester rather than a guess about how fast a task was scheduled.
        try await waitUntil { sut.pendingCallerCount == 1 }

        purchase.deliverPricingsReady()

        try await task.value
        #expect(sut.pendingCallerCount == 0)
    }

    @Test("stays subscribed after a request finishes, so a later request's outcome is not missed")
    func staysSubscribedAfterRequestFinishes() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .ready)

        try await sut.requestPricing()

        #expect(purchase.pricingDelegates.contains { ($0 as AnyObject) === sut })
    }

    // MARK: - Repeated requests

    /// Regression: transitioning to `.inFlight` without starting a request left every later caller
    /// queued behind a request that was never made.
    @Test("returns without starting a second request once the products are loaded")
    func afterSuccess_doesNotStartAnotherRequest() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .ready)

        try await sut.requestPricing()
        try await sut.requestPricing()

        #expect(purchase.requestPricingCallCount == 1)
    }

    @Test("retries after a failed request")
    func afterFailure_startsANewRequest() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .failed)

        try await sut.requestPricing()
        try await sut.requestPricing()

        #expect(purchase.requestPricingCallCount == 2)
    }

    /// The production failure path. `MEGAPurchase` dispatches `pricingsFailed` asynchronously to the
    /// main queue, so a failure can never land before the caller has queued — it always has to release
    /// a caller out of `pendingCallers`, and it always has to leave the state retryable.
    @Test("releases queued callers when the request fails, and the next caller retries")
    func queuedCallersResumeWhenTheRequestFails() async throws {
        let (sut, purchase) = makeSUT()
        let task = Task { try await sut.requestPricing() }
        try await waitUntil { sut.pendingCallerCount == 1 }

        purchase.deliverPricingsFailed()

        try await task.value
        #expect(sut.pendingCallerCount == 0)

        purchase.immediateResponse = .failed
        try await sut.requestPricing()
        #expect(purchase.requestPricingCallCount == 2)
    }

    /// Regression: a logout empties `MEGAPurchase.products`, so reporting the previous request as
    /// still loaded is what left the upgrade screen with no plans after logging back in.
    @Test("reloads the products after a cancel")
    func afterCancel_startsANewRequestAndWaitsForIt() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .ready)
        try await sut.requestPricing()

        sut.cancel()
        purchase.immediateResponse = .none

        let task = Task { try await sut.requestPricing() }

        try await waitUntil { sut.pendingCallerCount == 1 }
        #expect(purchase.requestPricingCallCount == 2)

        purchase.deliverPricingsReady()

        try await task.value
        #expect(sut.pendingCallerCount == 0)
    }

    // MARK: - Refreshing

    /// The difference from `requestPricing()`: the app-open promo trigger has to advertise on what the API
    /// says now, so a catalogue already loaded in this process is not good enough.
    @Test("forgets a completed request and loads the products again")
    func refresh_afterSuccess_startsANewRequest() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .ready)
        try await sut.requestPricing()

        try await sut.refreshPricing()

        #expect(purchase.requestPricingCallCount == 2)
        #expect(sut.pendingCallerCount == 0)
    }

    /// A request still in flight is loading the current catalogue already, so refreshing joins it. Restarting
    /// would drop back to `.idle` and strand everyone already waiting on it with a `CancellationError`, so this
    /// asserts the first caller resumes too rather than only counting requests.
    @Test("joins a request already in flight instead of restarting it, leaving its waiters intact")
    func refresh_whileInFlight_joinsTheExistingRequest() async throws {
        let (sut, purchase) = makeSUT()
        let waiting = Task { try await sut.requestPricing() }
        try await waitUntil { sut.pendingCallerCount == 1 }

        let refreshing = Task { try await sut.refreshPricing() }
        try await waitUntil { sut.pendingCallerCount == 2 }

        #expect(purchase.requestPricingCallCount == 1)

        purchase.deliverPricingsReady()

        try await waiting.value
        try await refreshing.value
        #expect(sut.pendingCallerCount == 0)
    }

    @Test("starts a request and waits for it when nothing has been loaded yet")
    func refresh_onAFreshRequester_startsARequestAndWaitsForIt() async throws {
        let (sut, purchase) = makeSUT()
        let task = Task { try await sut.refreshPricing() }

        try await waitUntil { sut.pendingCallerCount == 1 }
        #expect(purchase.requestPricingCallCount == 1)

        purchase.deliverPricingsReady()

        try await task.value
        #expect(sut.pendingCallerCount == 0)
    }

    /// A refresh that fails must release its caller and stay retryable, or the next app open waits on a
    /// catalogue that is never coming.
    @Test("releases the caller when the refreshed request fails, and the next refresh retries")
    func refresh_whenTheRequestFails_resumesAndStaysRetryable() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .failed)

        try await sut.refreshPricing()

        #expect(purchase.requestPricingCallCount == 1)
        #expect(sut.pendingCallerCount == 0)

        try await sut.refreshPricing()
        #expect(purchase.requestPricingCallCount == 2)
    }

    @Test("throws a cancellation error when the calling task is cancelled while a refresh waits")
    func refresh_callerCancelledWhileWaiting_throwsCancellationError() async throws {
        let (sut, _) = makeSUT()
        let task = Task { try await sut.refreshPricing() }
        try await waitUntil { sut.pendingCallerCount == 1 }

        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
        try await waitUntil { sut.pendingCallerCount == 0 }
    }

    // MARK: - Cancellation

    /// Cancelling an `SKProductsRequest` produces no delegate callback, so the requester itself is the only
    /// thing that can stop the waiters — and it has to stop the request at `MEGAPurchase` too, rather than
    /// leaving it running for products nobody wants.
    @Test("stops the request at MEGAPurchase and releases the waiters")
    func cancelWhileWaiting_cancelsTheRequestAndReleasesTheWaiter() async throws {
        let (sut, purchase) = makeSUT()
        let task = Task { try await sut.requestPricing() }
        try await waitUntil { sut.pendingCallerCount == 1 }

        sut.cancel()

        #expect(purchase.cancelPricingRequestCallCount == 1)
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(sut.pendingCallerCount == 0)
    }

    /// The cancel lands while the caller is between `requestPricing`'s lock release and being queued,
    /// so `addPendingCaller` finds `.idle`. Queueing there would park the caller behind a request
    /// nobody is going to finish.
    @Test("throws a cancellation error when the cancel lands before the caller is queued")
    func cancelBetweenStartAndQueueing_throwsCancellationError() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .cancel)

        await #expect(throws: CancellationError.self) { try await sut.requestPricing() }

        #expect(purchase.requestPricingCallCount == 1)
        #expect(sut.pendingCallerCount == 0)

        // Back at `.idle`, so the next caller reloads instead of trusting the emptied catalogue.
        purchase.immediateResponse = .ready
        try await sut.requestPricing()
        #expect(purchase.requestPricingCallCount == 2)
    }

    /// A cancel has to release *every* waiter, not just the one that started the request, and it has
    /// to leave the requester at `.idle` so the next caller reloads.
    @Test("throws for every caller when the request is cancelled while several wait")
    func cancelWhileSeveralCallersWait_throwsForAllOfThem() async throws {
        let (sut, purchase) = makeSUT()
        let tasks = (0..<3).map { _ in Task { try await sut.requestPricing() } }
        try await waitUntil { sut.pendingCallerCount == 3 }
        #expect(purchase.requestPricingCallCount == 1)

        sut.cancel()

        for task in tasks {
            await #expect(throws: CancellationError.self) { try await task.value }
        }
        #expect(sut.pendingCallerCount == 0)

        purchase.immediateResponse = .ready
        try await sut.requestPricing()
        #expect(purchase.requestPricingCallCount == 2)
    }

    @Test("throws a cancellation error when the calling task is cancelled while waiting")
    func cancelledWhileWaiting_throwsCancellationError() async throws {
        let (sut, _) = makeSUT()
        let task = Task { try await sut.requestPricing() }
        try await waitUntil { sut.pendingCallerCount == 1 }

        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(sut.pendingCallerCount == 0)
    }

    /// Whichever of cancellation and delivery wins, the caller's continuation must be resumed
    /// exactly once — resuming twice traps.
    @Test("delivering after a cancellation does not resume the caller twice")
    func deliveryAfterCancellation_doesNotResumeTwice() async throws {
        let (sut, purchase) = makeSUT()
        let task = Task { try await sut.requestPricing() }
        try await waitUntil { sut.pendingCallerCount == 1 }

        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(sut.pendingCallerCount == 0)

        purchase.deliverPricingsReady()
        sut.cancel()

        // Reaching here without trapping is the assertion; the requester is still usable.
        purchase.immediateResponse = .ready
        try await sut.requestPricing()
    }

    @Test("cancelling one caller leaves the others waiting on the same request")
    func cancellingOneCaller_leavesTheOthersWaiting() async throws {
        let (sut, purchase) = makeSUT()
        let cancelled = Task { try await sut.requestPricing() }
        let waiting = Task { try await sut.requestPricing() }
        try await waitUntil { sut.pendingCallerCount == 2 }

        cancelled.cancel()
        await #expect(throws: CancellationError.self) { try await cancelled.value }
        // `waiting` is still queued, so it provably has not been resumed alongside the cancelled one.
        #expect(sut.pendingCallerCount == 1)

        purchase.deliverPricingsReady()

        try await waiting.value
        #expect(purchase.requestPricingCallCount == 1)
    }

    /// Self-cancelling before the first suspension makes the outcome deterministic; cancelling from
    /// outside races the three cancellation points against each other. The assertions pin the
    /// behaviour — throws, and nothing left stranded — rather than which guard fired: `wait()`
    /// deliberately keeps a fallback re-check, so dropping `Task.checkCancellation()` alone still
    /// throws. Only removing both pre-suspension guards strands the caller and fails this test.
    @Test("throws without stranding the caller when the calling task is already cancelled")
    func alreadyCancelledTask_throwsWithoutStrandingTheCaller() async throws {
        let (sut, purchase) = makeSUT()

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.requestPricing()
        }

        await #expect(throws: CancellationError.self) { try await task.value }

        // The SDK request is fired before any cancellation check, so it still happens. What matters is
        // that no caller is left queued behind it.
        #expect(purchase.requestPricingCallCount == 1)
        #expect(sut.pendingCallerCount == 0)
    }

    // MARK: - Concurrency

    @Test("concurrent callers share a single request and all resume")
    func concurrentCallers_shareASingleRequest() async throws {
        let (sut, purchase) = makeSUT()
        let callerCount = 32

        let tasks = (0..<callerCount).map { _ in Task { try await sut.requestPricing() } }
        // Deliver only once every caller is provably queued, so this measures the shared-request path
        // rather than most of the callers resolving from a recorded `.succeeded`.
        try await waitUntil { sut.pendingCallerCount == callerCount }

        purchase.deliverPricingsReady()

        // Awaiting every task without throwing is the "all of them resumed" assertion.
        for task in tasks { try await task.value }
        #expect(purchase.requestPricingCallCount == 1)
        #expect(sut.pendingCallerCount == 0)
    }

    @Test("concurrent callers never start a second request once the products are loaded")
    func concurrentCallersAfterSuccess_neverStartAnotherRequest() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .ready)
        try await sut.requestPricing()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<32 {
                group.addTask { try? await sut.requestPricing() }
            }
            await group.waitForAll()
        }

        #expect(purchase.requestPricingCallCount == 1)
    }

    /// Hammers the lock from every direction at once: callers arriving, delegate callbacks landing on
    /// other threads, and tasks being cancelled mid-wait. Run under the Thread Sanitizer to make this
    /// earn its keep. Completing at all is the assertion — a lost caller deadlocks the group, a double
    /// resume traps.
    ///
    /// This is also the only coverage of `wait()`'s `if Task.isCancelled` re-check, which guards the
    /// window between queueing a caller and the cancellation handler firing. That window cannot be hit
    /// deterministically without a further seam, so it is covered probabilistically here.
    @Test("callers, callbacks and cancellations racing on several threads stay consistent")
    func concurrentCallersAndCallbacks_doNotDeadlockOrTrap() async throws {
        let (sut, purchase) = makeSUT(immediateResponse: .ready)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<64 {
                group.addTask { try? await sut.requestPricing() }
            }
            for _ in 0..<16 {
                group.addTask { purchase.deliverPricingsReady() }
                group.addTask { sut.cancel() }
                group.addTask { purchase.deliverPricingsFailed() }
            }
            for _ in 0..<16 {
                group.addTask {
                    let task = Task { try await sut.requestPricing() }
                    task.cancel()
                    _ = try? await task.value
                }
            }
            await group.waitForAll()
        }

        // The requester still works after the storm, and nobody was left queued.
        #expect(sut.pendingCallerCount == 0)
        purchase.immediateResponse = .ready
        try await sut.requestPricing()
    }
}

// MARK: - Helpers

private func makeSUT(
    immediateResponse: MockPricingPurchase.ImmediateResponse = .none
) -> (sut: PricingRequester, purchase: MockPricingPurchase) {
    let purchase = MockPricingPurchase(immediateResponse: immediateResponse)
    let sut = PricingRequester(purchase: purchase)
    purchase.startDelivering(to: sut)
    return (sut, purchase)
}

private struct TimedOut: Error {}

/// Polls `condition` so tests never assume how quickly a task reaches its suspension point. Records
/// the failure at the call site and throws, so a timeout stops the test instead of letting it run on
/// into assertions that would fail for the wrong reason.
private func waitUntil(
    timeout: Duration = .seconds(5),
    sourceLocation: SourceLocation = #_sourceLocation,
    _ condition: @Sendable () -> Bool
) async throws {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if condition() { return }
        try await Task.sleep(for: .milliseconds(5))
    }
    Issue.record("Timed out waiting for the expected condition", sourceLocation: sourceLocation)
    throw TimedOut()
}

/// A `MEGAPurchase` that never talks to the SDK, and lets the test decide when — and from which
/// thread — the pricing delegate callbacks land.
private final class MockPricingPurchase: MEGAPurchase, @unchecked Sendable {
    /// Reaction fired synchronously from `requestPricing()`, standing in for an outcome — or a logout
    /// `cancel()` — that lands before the caller gets to suspend.
    enum ImmediateResponse {
        case none
        case ready
        case failed
        case cancel
    }

    private let lock = NSLock()
    private var callCount = 0
    private var cancelCallCount = 0
    private var response: ImmediateResponse
    private var target: PricingRequester?

    var requestPricingCallCount: Int {
        lock.withLock { callCount }
    }

    var cancelPricingRequestCallCount: Int {
        lock.withLock { cancelCallCount }
    }

    var immediateResponse: ImmediateResponse {
        get { lock.withLock { response } }
        set { lock.withLock { response = newValue } }
    }

    init(immediateResponse: ImmediateResponse = .none) {
        response = immediateResponse
        super.init()
    }

    /// Deliveries go straight to the requester instead of through `MEGAPurchase.pricingDelegates`,
    /// whose getter blocks on a process-wide static serial queue. The stress test would otherwise make
    /// 48 concurrent blocking hops onto it, starving the cooperative thread pool and stalling every
    /// other test running in parallel.
    func startDelivering(to requester: PricingRequester) {
        lock.withLock { target = requester }
    }

    override func requestPricing() {
        lock.withLock { callCount += 1 }

        switch immediateResponse {
        case .none: break
        case .ready: deliverPricingsReady()
        case .failed: deliverPricingsFailed()
        case .cancel: currentTarget()?.cancel()
        }
    }

    /// Counted rather than performed: there is no real `SKProductsRequest` behind this mock.
    override func cancelPricingRequest() {
        lock.withLock { cancelCallCount += 1 }
    }

    func deliverPricingsReady() {
        currentTarget()?.pricingsReady()
    }

    func deliverPricingsFailed() {
        currentTarget()?.pricingsFailed()
    }

    /// Read under `lock`, then called outside it: the requester resumes callers while delivering, and
    /// a resumed caller can come straight back in through `requestPricing()`.
    private func currentTarget() -> PricingRequester? {
        lock.withLock { target }
    }
}
