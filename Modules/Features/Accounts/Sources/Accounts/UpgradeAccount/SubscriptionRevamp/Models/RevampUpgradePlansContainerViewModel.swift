import Combine
import MEGAAnalyticsiOS

/// Owns loading and the loading/standard/promo state switching for the revamp
/// Upgrade screen. Builds the content view model once the plans are loaded.
@MainActor
public final class RevampUpgradePlansContainerViewModel: ObservableObject {
    public enum ViewState {
        case loading
        case standard(RevampUpgradePlansViewModel)
        case promo(RevampUpgradePlansViewModel)
    }

    private let dependency: RevampUpgradePlansDependency

    @Published public private(set) var viewState: ViewState = .loading
    @Published public var isDismiss = false
    @Published public var isAlertPresented = false

    // [IOS-12239]: Handle error alert
    public private(set) var alertType: UpgradeAccountPlanAlertType?

    public init(dependency: RevampUpgradePlansDependency) {
        self.dependency = dependency
    }

    public func onLoad() {
        dependency.tracker.trackAnalyticsEvent(with: UpgradeAccountPlanScreenEvent())
    }

    public func loadData() async {
        viewState = .loading

        do {
            // [IOS-12240]: Construct the correct viewModel
            _ = try await dependency.fetchUseCase.currentAccountDetails()
            let plans = await dependency.fetchUseCase.plans()
            let hasPromo = plans.contains(where: { $0.introductoryOffer != nil })
            viewState = hasPromo ? .promo(.promo) : .standard(.standard)
        } catch {
            showErrorAlert()
        }
    }

    private func showErrorAlert() {
        // [IOS-12239]: Show error alert
    }
}
