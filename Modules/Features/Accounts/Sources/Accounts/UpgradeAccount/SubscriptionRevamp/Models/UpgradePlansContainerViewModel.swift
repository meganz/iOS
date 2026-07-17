import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGADomain

/// Owns loading and the loading/standard/promo state switching for the revamp
/// Upgrade screen. Builds the content view model once the plans are loaded.
@MainActor
public final class UpgradePlansContainerViewModel: ObservableObject {
    public enum ViewState {
        case loading
        case standard(RevampUpgradePlansViewModel)
        case promo(RevampUpgradePlansViewModel)
    }

    let dependency: RevampUpgradePlansDependency
    private var subscriptions = Set<AnyCancellable>()

    @Published public private(set) var viewState: ViewState = .loading
    @Published public var isDismiss = false
    @Published public var isAlertPresented = false

    // [IOS-12239]: Handle error alert
    public private(set) var alertType: UpgradeAccountPlanAlertType?

    public init(dependency: RevampUpgradePlansDependency) {
        self.dependency = dependency
        observeRestoreResult()
    }

    deinit {
        Task { [purchaseUseCase = dependency.purchaseUseCase] in
            await purchaseUseCase.deRegisterRestoreDelegate()
        }
    }

    public func onAppear() {
        dependency.tracker.trackAnalyticsEvent(with: UpgradeAccountPlanScreenEvent())
    }

    public func loadData() async {
        viewState = .loading
        await dependency.purchaseUseCase.registerRestoreDelegate()

        do {
            // [IOS-12240]: Construct the correct viewModel
            _ = try await dependency.fetchUseCase.currentAccountDetails()
            let plans = await dependency.fetchUseCase.plans()
            let hasPromo = plans.contains(where: { $0.introductoryOffer != nil })
            let contentViewModel = RevampUpgradePlansViewModel(
                isPromo: hasPromo
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
