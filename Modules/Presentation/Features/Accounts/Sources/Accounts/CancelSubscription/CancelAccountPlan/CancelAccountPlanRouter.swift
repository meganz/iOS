import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import StoreKit
import SwiftUI

public protocol CancelAccountPlanRouting: Routing {
    func dismissCancellationFlow()
    func showAppleManageSubscriptions()
}

public final class CancelAccountPlanRouter: CancelAccountPlanRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let currentSubscription: AccountSubscriptionEntity
    private let accountUseCase: any AccountUseCaseProtocol
    private let currentPlan: PlanEntity
    private let assets: CancelAccountPlanAssets
    
    private var appleIDSubscriptionsURL: URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }
    
    /// CancelAccountPlanRouter is used to manage redirections of the cancel subscription flow
    /// - Parameters:
    ///   - currentSubscription: Holds the current active subscription details.
    ///   - accountUseCase: A use case handling account-related functionalities and actions.
    ///   - currentPlan: Contains the details of the user's current subscribed plan.
    ///   - assets: Holds the asset names (such as images) for display in the flow.
    ///   - navigationController: The navigation controller that manages presenting and dismissing the views related to the cancel account plan flow.
    public init(
        currentSubscription: AccountSubscriptionEntity,
        accountUseCase: some AccountUseCaseProtocol,
        currentPlan: PlanEntity,
        assets: CancelAccountPlanAssets,
        navigationController: UINavigationController
    ) {
        self.currentSubscription = currentSubscription
        self.accountUseCase = accountUseCase
        self.currentPlan = currentPlan
        self.assets = assets
        self.navigationController = navigationController
    }
    
    public func build() -> UIViewController {
        let featureListHelper = FeatureListHelper(
            currentPlan: currentPlan,
            assets: assets
        )
        
        let viewModel = CancelAccountPlanViewModel(
            currentSubscription: currentSubscription,
            featureListHelper: featureListHelper, 
            achievementUseCase: AchievementUseCase(repo: AchievementRepository.newRepo),
            accountUseCase: accountUseCase,
            tracker: DIContainer.tracker,
            router: self
        )
        
        let hostingController = UIHostingController(
            rootView: CancelAccountPlanView(viewModel: viewModel)
        )
        baseViewController = hostingController
        return hostingController
    }
    
    public func start() {
        let viewController = build()
        navigationController?.topViewController?.present(viewController, animated: true)
    }
    
    public func dismissCancellationFlow() {
        navigationController?.topViewController?.dismiss(animated: true)
        navigationController?.popViewController(animated: false)
    }

    public func showAppleManageSubscriptions() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              !ProcessInfo.processInfo.isiOSAppOnMac else {
            openAppleIDSubscriptionsPage()
            return
        }
        
        Task {
            do {
                try await AppStore.showManageSubscriptions(in: scene)
                
                /// Dismiss cancellation flow after closing Manage subscription page
                dismissCancellationFlow()
            } catch {
                openAppleIDSubscriptionsPage()
            }
        }
    }
    
    private func openAppleIDSubscriptionsPage() {
        guard let url = appleIDSubscriptionsURL else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
