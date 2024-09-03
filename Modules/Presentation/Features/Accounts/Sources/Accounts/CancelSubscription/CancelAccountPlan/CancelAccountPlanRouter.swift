import MEGADomain
import MEGAPresentation
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
    private let accountDetails: AccountDetailsEntity
    private let currentPlan: PlanEntity
    private let assets: CancelAccountPlanAssets
    
    private var appleIDSubscriptionsURL: URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }
    
    /// CancelAccountPlanRouter is used to manage redirections of the cancel subscription flow
    /// - Parameter currentSubscription: Holds the current active subscription
    /// - Parameter accountDetails: Contains the account details of the user
    /// - Parameter currentPlan: Holds the current subscribed plan
    /// - Parameter assets: Contains the Image names of the assets
    /// - Parameter navigationController: Holds the navigation that pushes the presenter of `CancelAccountPlanRouter`. Manages the redirections.
    public init(
        currentSubscription: AccountSubscriptionEntity,
        accountDetails: AccountDetailsEntity,
        currentPlan: PlanEntity,
        assets: CancelAccountPlanAssets,
        navigationController: UINavigationController
    ) {
        self.currentSubscription = currentSubscription
        self.accountDetails = accountDetails
        self.currentPlan = currentPlan
        self.assets = assets
        self.navigationController = navigationController
    }
    
    public func build() -> UIViewController {
        let featureListHelper = FeatureListHelper(
            account: accountDetails,
            currentPlan: currentPlan,
            assets: assets
        )
        
        let viewModel = CancelAccountPlanViewModel(
            currentSubscription: currentSubscription, 
            currentPlanName: accountDetails.proLevel.toAccountTypeDisplayName(),
            currentPlanStorageUsed: String.memoryStyleString(fromByteCount: accountDetails.storageUsed),
            featureListHelper: featureListHelper, 
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
