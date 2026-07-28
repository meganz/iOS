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
        await dependency.purchaseUseCase.registerRestoreDelegate()

        do {
            async let accountDetailsResult = dependency.fetchUseCase.currentAccountDetails()
            async let plansResult = dependency.fetchUseCase.plans()
            let accountDetails = try await accountDetailsResult
            let plans = await plansResult
            
            let hasPromo = plans.contains { $0.introductoryOffer != nil || $0.hasValidPromotionalOffer }
            let contentViewModel = UpgradePlansViewModel(
                isPromo: hasPromo,
                viewType: dependency.viewType,
                accountDetails: accountDetails,
                plans: plans,
                displayName: dependency.accountDisplayName
            )
            viewState = hasPromo ? .promo(contentViewModel) : .standard(contentViewModel)
        } catch {
            showInitialLoadingAlert()
        }
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
