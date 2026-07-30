import Combine
import Foundation
import MEGAAnalyticsiOS
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

    @Published public private(set) var viewState: ViewState = .loading
    @Published public var isDismiss = false
    @Published public var isAlertPresented = false

    // [IOS-12239]: Handle error alert
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

    func loadData() async {
        viewState = .loading
        promoExpiryMonitor = nil
        await dependency.purchaseUseCase.registerRestoreDelegate()

        do {
            async let accountDetailsResult = dependency.fetchUseCase.currentAccountDetails()
            async let plansResult = dependency.fetchUseCase.plans()
            let accountDetails = try await accountDetailsResult
            let plans = await plansResult

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
            displayName: dependency.accountDisplayName
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

    private func presentAlert(_ type: UpgradeAccountPlanAlertType) {
        alertType = type
        isAlertPresented = true
    }

    private func showInitialLoadingAlert() {
        // [IOS-12239]: Show error alert
    }
}
