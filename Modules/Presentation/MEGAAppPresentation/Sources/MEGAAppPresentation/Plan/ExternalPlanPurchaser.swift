import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGAAppSDKRepo
import MEGADomain

/// Sends the user to the MEGA website to buy a plan, and reports progress as ``PlanPurchaseOutcome`` values.
///
/// A sibling of ``PlanPurchasing`` rather than an extension of it: this route needs the whole ``PlanEntity``
/// (for the website path, the billing span and the plan level it should end up at), and keeping the two apart
/// means no in-app purchaser can accidentally inherit a website purchase it cannot perform.
@MainActor
public protocol ExternalPlanPurchasing {
    var outcomes: AnyPublisher<PlanPurchaseOutcome, Never> { get }

    /// - Parameter onWebsiteOpened: called once the browser has the purchase, which is neither a success nor
    ///   a failure: the attempt is no longer busy, and its result arrives later through `outcomes`. Not
    ///   called when no website link can be opened, which reports `.failed`.
    func purchase(plan: PlanEntity, onWebsiteOpened: @escaping @MainActor () -> Void) async
}

/// Buys a plan on the MEGA website instead of through the App Store.
///
/// `purchase` applies the same ``PlanPurchaseEligibilityChecker`` as the in-app route, then opens a
/// session-carrying link.
/// When no link can be opened the attempt reports `.failed`, so the user is told the website route did not
/// work rather than being moved to the App Store behind their back, as the legacy screen did.
///
/// The website never tells the app what happened, so completion is detected from the account itself: the
/// observation starts *before* the browser opens, and each account update refreshes the details until the
/// account reports the plan that was bought.
///
/// Handing the purchase to the browser is reported through `onWebsiteOpened` rather than as an outcome,
/// because it is a state only this route has: the in-app purchaser could never emit it.
@MainActor
public final class ExternalPlanPurchaser: ExternalPlanPurchasing {
    private let linkProvider: any ExternalPurchaseLinkProviding
    private let accountUseCase: any AccountUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let eligibilityChecker: any PlanPurchaseEligibilityChecking
    private let tracker: any AnalyticsTracking
    /// Delay between the account reporting the plan and emitting `.succeeded`, matching the in-app route.
    private let postPurchaseDelay: TimeInterval
    private let domainName: String
    private let appVersion: String
    private let canOpenURL: @Sendable (URL) async -> Bool
    private let openURL: @Sendable (URL) async -> Void

    private let outcomesSubject = PassthroughSubject<PlanPurchaseOutcome, Never>()
    /// Watches the account for the plan the user went off to buy. Runs from before the browser opens until
    /// the plan lands, a new purchase starts, or this purchaser goes away.
    private var completionTask: Task<Void, Never>?
    /// While a link request is in flight, blocks a second one, so a double tap can't open two pages.
    private var isPurchaseInFlight = false

    public var outcomes: AnyPublisher<PlanPurchaseOutcome, Never> {
        outcomesSubject.eraseToAnyPublisher()
    }

    public init(
        linkProvider: some ExternalPurchaseLinkProviding,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo),
        eligibilityChecker: some PlanPurchaseEligibilityChecking = PlanPurchaseEligibilityChecker(),
        tracker: some AnalyticsTracking,
        domainName: String,
        appVersion: String,
        postPurchaseDelay: TimeInterval = 1,
        canOpenURL: @escaping @Sendable (URL) async -> Bool,
        openURL: @escaping @Sendable (URL) async -> Void
    ) {
        self.linkProvider = linkProvider
        self.accountUseCase = accountUseCase
        self.purchaseUseCase = purchaseUseCase
        self.eligibilityChecker = eligibilityChecker
        self.tracker = tracker
        self.postPurchaseDelay = postPurchaseDelay
        self.domainName = domainName
        self.appVersion = appVersion
        self.canOpenURL = canOpenURL
        self.openURL = openURL
    }

    deinit {
        completionTask?.cancel()
    }

    public func purchase(plan: PlanEntity, onWebsiteOpened: @escaping @MainActor () -> Void) async {
        guard !isPurchaseInFlight else { return }

        switch eligibilityChecker.eligibility() {
        case .purchasable:
            await runPurchase(plan: plan, onWebsiteOpened: onWebsiteOpened)
        case .hasCancellableSubscription:
            outcomesSubject.send(.requiresCancellationConfirmation(confirmCancelAndBuy: { [weak self] in
                await self?.runCancelThenPurchase(plan: plan, onWebsiteOpened: onWebsiteOpened)
            }))
        case .hasNonCancellableSubscription:
            outcomesSubject.send(.cannotPurchaseWithActiveSubscription)
        }
    }

    // MARK: - Purchase flows

    private func runPurchase(plan: PlanEntity, onWebsiteOpened: @escaping @MainActor () -> Void) async {
        guard !isPurchaseInFlight else { return }
        beginPurchasing()
        await openWebsite(for: plan, onWebsiteOpened: onWebsiteOpened)
    }

    /// The user confirmed cancel-then-buy: clear the active subscription, then continue on the website - the
    /// route they actually chose.
    private func runCancelThenPurchase(plan: PlanEntity, onWebsiteOpened: @escaping @MainActor () -> Void) async {
        guard !isPurchaseInFlight else { return }
        beginPurchasing()
        guard await eligibilityChecker.cancelActiveSubscription(),
              await eligibilityChecker.refreshedEligibility() == .purchasable else {
            endPurchasing()
            tracker.trackAnalyticsEvent(with: UpgradeAccountPurchaseFailedEvent())
            outcomesSubject.send(.failed)
            return
        }
        await openWebsite(for: plan, onWebsiteOpened: onWebsiteOpened)
    }

    private func openWebsite(for plan: PlanEntity, onWebsiteOpened: @escaping @MainActor () -> Void) async {
        guard let url = await openableLink(for: plan) else {
            endPurchasing()
            tracker.trackAnalyticsEvent(with: UpgradeAccountPurchaseFailedEvent())
            outcomesSubject.send(.failed)
            return
        }

        // Started before the browser opens, so an account update that lands while the user is still on the
        // website is not missed.
        observeAccountUpdates(for: plan)
        await openURL(url)
        endPurchasing()
        onWebsiteOpened()
    }

    // MARK: - Purchase steps

    /// The website link for a plan, or `nil` when the route is no longer offered, no link can be built, or
    /// the device cannot open it.
    private func openableLink(for plan: PlanEntity) async -> URL? {
        guard await linkProvider.shouldProvideExternalPurchase(),
              let url = try? await linkProvider.externalPurchaseLink(
            domain: domainName,
            path: plan.externalPurchasePath,
            sourceApp: "iOS app Ver \(appVersion)",
            months: months(for: plan.subscriptionCycle)
        ), await canOpenURL(url) else { return nil }

        return url
    }

    private func months(for cycle: SubscriptionCycleEntity) -> Int? {
        switch cycle {
        case .monthly: 1
        case .yearly: 12
        default: nil
        }
    }

    private func beginPurchasing() {
        isPurchaseInFlight = true
        outcomesSubject.send(.purchasing)
    }

    private func endPurchasing() {
        isPurchaseInFlight = false
    }

    // MARK: - Completion detection

    private func observeAccountUpdates(for plan: PlanEntity) {
        completionTask?.cancel()
        completionTask = Task { [weak self, accountUseCase] in
            for await _ in accountUseCase.onAccountUpdates {
                guard !Task.isCancelled else { return }
                guard await self?.didAccountReceive(plan) == true else { continue }
                // The refresh suspended, so a newer attempt or a teardown may have taken over meanwhile.
                guard !Task.isCancelled else { return }
                await self?.handlePurchaseSucceeded()
                // The account reported the plan, so nothing is left to watch for.
                return
            }
        }
    }

    /// Whether the account now reports the plan the user went off to buy.
    private func didAccountReceive(_ plan: PlanEntity) async -> Bool {
        guard let details = try? await accountUseCase.refreshAccountAndMonitorUpdate() else { return false }
        return details.proLevel == plan.type
    }

    /// Settles the purchase the same way the in-app route does, so a plan bought on the website dismisses
    /// the screen identically.
    private func handlePurchaseSucceeded() async {
        NotificationCenter.default.post(name: .accountDidPurchasedPlan, object: nil)
        tracker.trackAnalyticsEvent(with: UpgradeAccountPurchaseSucceededEvent())
        purchaseUseCase.startMonitoringSubmitReceiptAfterPurchase()

        if postPurchaseDelay > 0 {
            try? await Task.sleep(for: .seconds(postPurchaseDelay))
        }
        guard !Task.isCancelled else { return }
        outcomesSubject.send(.succeeded)
        completionTask = nil
    }
}
