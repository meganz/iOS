import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGAAppSDKRepo
import MEGADomain

/// The mutually-exclusive phases of a one-tap plan purchase
public enum PlanPurchaseOutcome: Sendable {
    /// A purchase is in flight (kicked off, or cancelling-then-rebuying). Drives the busy / disabled UI.
    case purchasing
    /// Blocked by a web subscription that can be cancelled in-app
    /// Ask the user to confirm, then invoke `confirmCancelAndBuy` to cancel it and continue the purchase.
    case requiresCancellationConfirmation(confirmCancelAndBuy: @MainActor () async -> Void)
    /// Blocked by a subscription that can't be cancelled in-app
    case cannotPurchaseWithActiveSubscription
    /// Purchase completed successfully. Side effects (notification, receipt monitoring) already ran;
    /// The consumer should dismiss / advance its UI.
    case succeeded
    /// Purchase failed for a reason worth surfacing to the user (not a cancellation).
    case failed
    /// The user cancelled the StoreKit purchase, no UI reaction needed.
    case cancelled
}

/// Runs a one-tap plan purchase and reports progress as ``PlanPurchaseOutcome`` values. Consumers depend on
/// this (not the concrete ``PlanPurchaser``) so previews / QA can inject a scripted mock.
@MainActor
public protocol PlanPurchasing {
    var outcomes: AnyPublisher<PlanPurchaseOutcome, Never> { get }
    func purchase(productIdentifier: String) async
}

/// Runs a one-tap plan purchase and reports what happens back to a view model through `outcomes`. Shared by
/// the quota dialog and (later) the revamp subscription page so they work the same way.
///
/// When `purchase` is called it looks at the current account (from cached details) and picks one path:
/// - Nothing is in the way: start the StoreKit purchase right away (`runDirectPurchase`).
/// - The user has a web subscription that can be cancelled in the app: ask the user to confirm; if they
///   agree, cancel it first and then start the purchase (`runCancelThenPurchase`).
/// - The user has a subscription that can't be cancelled in the app: tell the user it can't proceed.
///
/// The StoreKit purchase does not finish right away, its result comes back later on
/// `purchasePlanResultPublisher`.
/// - On success the controller posts `.accountDidPurchasedPlan` once and asks the view to dismiss (after `postPurchaseDelay`).
/// - Any failure, from any step, goes through one place: `handlePurchaseError`.
@MainActor
public final class PlanPurchaser: PlanPurchasing {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let eligibilityChecker: any PlanPurchaseEligibilityChecking
    private let tracker: any AnalyticsTracking
    /// Delay between the purchase succeeding (side effects run immediately) and emitting `.succeeded`
    /// (which drives dismissal). Mirrors the legacy screen's 1s window for `.accountDidPurchasedPlan`
    /// observers; pass `0` to dismiss immediately (e.g. the quota dialog, whose host does not observe it).
    private let postPurchaseDelay: TimeInterval

    private let outcomesSubject = PassthroughSubject<PlanPurchaseOutcome, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private var dismissTask: Task<Void, Never>?
    /// While a purchase is running, blocks a second one, so a double tap can't start two payments.
    private var isPurchaseInFlight = false

    public var outcomes: AnyPublisher<PlanPurchaseOutcome, Never> {
        outcomesSubject.eraseToAnyPublisher()
    }

    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        eligibilityChecker: some PlanPurchaseEligibilityChecking = PlanPurchaseEligibilityChecker(),
        tracker: some AnalyticsTracking,
        postPurchaseDelay: TimeInterval = 1
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.eligibilityChecker = eligibilityChecker
        self.tracker = tracker
        self.postPurchaseDelay = postPurchaseDelay
        observePurchaseResult()
    }

    deinit {
        Task { [purchaseUseCase] in
            await purchaseUseCase.deRegisterPurchaseDelegate()
        }
    }

    public func purchase(productIdentifier: String) async {
        guard !isPurchaseInFlight else { return }

        switch eligibilityChecker.eligibility() {
        case .purchasable:
            await runDirectPurchase(productIdentifier: productIdentifier)
        case .hasCancellableSubscription:
            outcomesSubject.send(.requiresCancellationConfirmation(confirmCancelAndBuy: { [weak self] in
                await self?.runCancelThenPurchase(productIdentifier: productIdentifier)
            }))
        case .hasNonCancellableSubscription:
            outcomesSubject.send(.cannotPurchaseWithActiveSubscription)
        }
    }

    // MARK: - Purchase Flows

    /// Straight-through purchase: hand off to StoreKit.
    private func runDirectPurchase(productIdentifier: String) async {
        guard !isPurchaseInFlight else { return }
        beginPurchasing()
        await startStoreKitPurchase(productIdentifier: productIdentifier)
    }

    /// The user confirmed cancel-then-buy: cancel active subscription first, then hand off to StoreKit
    private func runCancelThenPurchase(productIdentifier: String) async {
        guard !isPurchaseInFlight else { return }
        beginPurchasing()
        guard await eligibilityChecker.cancelActiveSubscription() else {
            handlePurchaseError(.subscriptionCancellationFailed)
            return
        }
        guard await eligibilityChecker.refreshedEligibility() == .purchasable else {
            handlePurchaseError(.subscriptionStillActive)
            return
        }
        await startStoreKitPurchase(productIdentifier: productIdentifier)
    }

    // MARK: - Purchase steps

    private func startStoreKitPurchase(productIdentifier: String) async {
        await purchaseUseCase.registerPurchaseDelegate()
        await purchaseUseCase.purchasePlan(productIdentifier: productIdentifier)
        // Result arrives asynchronously on `purchasePlanResultPublisher()` → `handlePurchaseResult`.
    }

    private func beginPurchasing() {
        isPurchaseInFlight = true
        outcomesSubject.send(.purchasing)
    }

    private func endPurchasing() {
        isPurchaseInFlight = false
    }

    // MARK: - Result handling

    private func observePurchaseResult() {
        purchaseUseCase.purchasePlanResultPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.handlePurchaseResult(result)
            }
            .store(in: &subscriptions)
    }

    private func handlePurchaseResult(_ result: Result<Void, AccountPlanErrorEntity>) {
        switch result {
        case .success:
            handlePurchaseSucceeded()
        case .failure(let error):
            let flowError: PurchaseFlowError = if error.toPurchaseErrorStatus() == .paymentCancelled {
                .cancelledByUser
            } else {
                .storeKitPurchaseFailed
            }
            handlePurchaseError(flowError)
        }
    }

    private func handlePurchaseSucceeded() {
        NotificationCenter.default.post(name: .accountDidPurchasedPlan, object: nil)
        tracker.trackAnalyticsEvent(with: UpgradeAccountPurchaseSucceededEvent())

        guard postPurchaseDelay > 0 else {
            purchaseUseCase.startMonitoringSubmitReceiptAfterPurchase()
            endPurchasing()
            outcomesSubject.send(.succeeded)
            return
        }
        dismissTask?.cancel()
        dismissTask = Task { [weak self, delay = postPurchaseDelay] in
            try? await Task.sleep(for: .seconds(delay))
            self?.purchaseUseCase.startMonitoringSubmitReceiptAfterPurchase()
            guard !Task.isCancelled else { return }
            self?.endPurchasing()
            self?.outcomesSubject.send(.succeeded)
        }
    }

    private func handlePurchaseError(_ error: PurchaseFlowError) {
        tracker.trackAnalyticsEvent(with: UpgradeAccountPurchaseFailedEvent())
        endPurchasing()
        switch error {
        case .cancelledByUser:
            outcomesSubject.send(.cancelled)
        case .subscriptionCancellationFailed, .subscriptionStillActive, .storeKitPurchaseFailed:
            outcomesSubject.send(.failed)
        }
    }
}

/// Every way a purchase flow can end without success.
private enum PurchaseFlowError: Error {
    /// Cancelling the active web subscription failed.
    case subscriptionCancellationFailed
    /// After a successful cancel, the account still isn't purchasable.
    case subscriptionStillActive
    /// StoreKit reported a non-cancellation failure.
    case storeKitPurchaseFailed
    /// The user aborted the StoreKit purchase sheet
    case cancelledByUser
}
