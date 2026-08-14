import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain

/// Owns loading and the loading/standard/promo state switching for the revamp
/// Upgrade screen. Builds the content view model once the plans are loaded.
@MainActor
final class UpgradePlansContainerViewModel: ObservableObject {
    public enum ViewState {
        case loading
        case standard(UpgradePlansViewModel)
        case promo(UpgradePlansViewModel)
    }

    let dependency: RevampUpgradePlansDependency
    private var subscriptions = Set<AnyCancellable>()
    /// Drives the flip to `.standard` once the featured promotional offer lapses.
    /// Set only while a promo page with a live countdown is shown.
    private var promoExpiryMonitor: (any PromoExpiryMonitoring)?
    /// Whether "buy on our website" is offered at all, resolved once per load.
    private var isExternalPurchaseAvailable = false
    /// Owns the retry triggered from the load error alert, so a new attempt supersedes the one in flight.
    private var retryTask: Task<Void, Never>?

    private(set) lazy var purchaseViewModel = PlanPurchaseViewModel(
        planPurchaser: dependency.planPurchaserFactory.makePurchaser(
            purchaseUseCase: dependency.purchaseUseCase,
            subscriptionsUseCase: dependency.subscriptionsUseCase,
            accountUseCase: dependency.accountUseCase
        ),
        onPurchased: { [weak self] in
            self?.purchaseDidSucceed()
        }
    )

    /// Drives the "buy on our website" buttons. Needs the loaded plans, so it only exists from the first
    /// successful load, and only when that route is available at all.
    private(set) var externalPurchaseViewModel: ExternalPurchaseViewModel?

    @Published public private(set) var viewState: ViewState = .loading
    @Published public var isDismiss = false
    @Published public var isAlertPresented = false

    private(set) var alertType: UpgradeAccountPlanAlertType?

    init(dependency: RevampUpgradePlansDependency) {
        self.dependency = dependency
        observeRestoreResult()
    }

    deinit {
        Task { [purchaseUseCase = dependency.purchaseUseCase] in
            await purchaseUseCase.deRegisterRestoreDelegate()
        }
    }

    func onAppear() {
        dependency.tracker.trackAnalyticsEvent(with: UpgradeAccountPlanScreenEvent())
    }

    func dismiss() {
        guard !isDismiss else { return }
        if dependency.viewType.isOnboarding {
            dependency.tracker.trackAnalyticsEvent(with: MaybeLaterUpgradeAccountButtonPressedEvent())
        }
        isDismiss = true
    }

    func load() async {
        await loadData()
        await monitorPromoExpiry()
    }

    func loadData() async {
        viewState = .loading
        promoExpiryMonitor = nil
        await dependency.purchaseUseCase.registerRestoreDelegate()

        do {
            async let accountDetailsResult = dependency.fetchUseCase.currentAccountDetails()
            async let plansResult = dependency.fetchUseCase.plans()
            async let externalPurchaseAvailability = dependency.externalPurchaseUseCase.shouldProvideExternalPurchase()
            let accountDetails = try await accountDetailsResult
            let plans = await plansResult
            isExternalPurchaseAvailable = await externalPurchaseAvailability
            externalPurchaseViewModel = makeExternalPurchaseViewModel(plans: plans)

            let hasPromo = plans.contains { $0.applicableOffer != nil && !$0.isCurrentPlan(for: accountDetails) }
            guard hasPromo else {
                viewState = .standard(makeContentViewModel(isPromo: false, accountDetails: accountDetails, plans: plans))
                return
            }

            let promoViewModel = makeContentViewModel(isPromo: true, accountDetails: accountDetails, plans: plans)
            guard let deadline = promoViewModel.promoCountdownDeadline else {
                viewState = .promo(promoViewModel) // Promo with no countdown, nothing to expire.
                return
            }

            let monitor = dependency.promoExpiryMonitorFactory.makeMonitor(
                deadline: deadline,
                accountDetails: accountDetails,
                plans: plans
            )
            guard !monitor.hasAlreadyExpired else { // Safeguard in case deadline is earlier than current time
                viewState = .standard(makeStandardViewModel(from: monitor))
                return
            }
            viewState = .promo(promoViewModel)
            promoExpiryMonitor = monitor
        } catch {
            showInitialLoadingAlert()
        }
    }

    func monitorPromoExpiry() async {
        guard let monitor = promoExpiryMonitor else { return }
        guard await monitor.waitUntilExpired(),
              promoExpiryMonitor === monitor, // still the active monitor (no reload superseded it)
              case .promo(let promoViewModel) = viewState else { return }

        // Strip the lapsed offers and flip to standard immediately - the correctness-critical transition
        // must not be gated on the alert, which can be dropped when another alert is already on screen.
        let standardViewModel = makeStandardViewModel(from: monitor)
        standardViewModel.selectedCycle = promoViewModel.selectedCycle
        viewState = .standard(standardViewModel)
        promoExpiryMonitor = nil

        presentAlert(.promoEnded)
    }

    private func makeContentViewModel(
        isPromo: Bool,
        accountDetails: AccountDetailsEntity,
        plans: [PlanEntity]
    ) -> UpgradePlansViewModel {
        UpgradePlansViewModel(
            isPromo: isPromo,
            viewType: dependency.viewType,
            accountDetails: accountDetails,
            plans: plans,
            displayName: dependency.accountDisplayName,
            isExternalPurchaseAvailable: isExternalPurchaseAvailable,
            recommendedPlanUseCase: dependency.recommendedUpgradePlanUseCase
        )
    }

    private func makeExternalPurchaseViewModel(plans: [PlanEntity]) -> ExternalPurchaseViewModel? {
        guard isExternalPurchaseAvailable else { return nil }

        return ExternalPurchaseViewModel(
            purchaser: dependency.planPurchaserFactory.makeExternalPurchaser(
                linkProvider: ExternalPurchaseLinkProvider(useCase: dependency.externalPurchaseUseCase),
                purchaseUseCase: dependency.purchaseUseCase,
                accountUseCase: dependency.accountUseCase,
                domainName: dependency.domainName,
                appVersion: dependency.appVersion,
                canOpenURL: dependency.canOpenURL,
                openURL: dependency.openURL
            ),
            plans: plans,
            onPurchased: { [weak self] in
                self?.purchaseDidSucceed()
            }
        )
    }

    /// Builds the standard page shown once a promotion has lapsed, sourcing the account details and
    /// offer-stripped plans from the monitor so no stale discount survives the switch.
    private func makeStandardViewModel(from monitor: some PromoExpiryMonitoring) -> UpgradePlansViewModel {
        makeContentViewModel(
            isPromo: false,
            accountDetails: monitor.accountDetails,
            plans: monitor.plansAfterExpiry
        )
    }

    private func observeRestoreResult() {
        dependency.purchaseUseCase.successfulRestorePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.presentAlert(.restore(.success)) }
            .store(in: &subscriptions)

        dependency.purchaseUseCase.incompleteRestorePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.presentAlert(.restore(.incomplete)) }
            .store(in: &subscriptions)

        dependency.purchaseUseCase.failedRestorePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.presentAlert(.restore(.failed)) }
            .store(in: &subscriptions)
    }

    private func purchaseDidSucceed() {
        dependency.notifyPurchaseSucceeded()
        // [IOS-12341]: Handle non-loading state of AccountMenuView's .currentPlan and .storageUsed rows
        switch dependency.purchaseCompleteBehavior {
        case .dismiss:
            guard !isDismiss else { return }
            isDismiss = true
        case let .perform(action):
            action()
        }
    }

    private func presentAlert(_ type: UpgradeAccountPlanAlertType) {
        alertType = type
        isAlertPresented = true
    }

    private func showInitialLoadingAlert() {
        presentAlert(
            .loadFailed(
                retryAction: { [weak self] in
                    self?.retryLoad()
                },
                dismissAction: { [weak self] in
                    guard let self, !isDismiss else { return }
                    isDismiss = true
                }
            )
        )
    }

    private func retryLoad() {
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            await self?.load()
        }
    }
}
