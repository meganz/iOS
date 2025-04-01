import MEGAAppPresentation
import MEGADomain
import MEGASDKRepo
import MEGASwift
import StoreKit
import SwiftUI

public protocol CancelAccountPlanRouting: Routing {
    func dismissCancellationFlow(completion: (() -> Void)?)
    func showAppleManageSubscriptions()
    func showAlert(_ result: CancelSubscriptionResult)
    
    typealias CancelSubscriptionResult = Result<Date, Error>
}

extension CancelAccountPlanRouting {
    func dismissCancellationFlow() {
        dismissCancellationFlow(completion: nil)
    }
}

public final class CancelAccountPlanRouter: CancelAccountPlanRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let currentSubscription: AccountSubscriptionEntity
    private let freeAccountStorageLimit: Int
    private let accountUseCase: any AccountUseCaseProtocol
    private let currentPlan: PlanEntity
    private let assets: CancelAccountPlanAssets
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    private var appleIDSubscriptionsURL: URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }
    
    private let onSuccess: (
        _ expirationDate: Date,
        _ storageLimit: Int
    ) -> Void
    private let onFailure: (
        _ onContactSupportTapped: @escaping () -> Void
    ) -> Void
    
    /// CancelAccountPlanRouter is used to manage redirections of the cancel subscription flow
    /// - Parameters:
    ///   - currentSubscription: Holds the current active subscription details.
    ///   - freeAccountStorageLimit: Specifies the storage limit (in GB or other units) available for free accounts after cancellation.
    ///   - accountUseCase: A use case handling account-related functionalities and actions.
    ///   - currentPlan: Contains the details of the user's current subscribed plan.
    ///   - assets: Holds the asset names (such as images) for display in the flow.
    ///   - navigationController: The navigation controller that manages presenting and dismissing the views related to the cancel account plan flow.
    ///   - onSuccess: A closure that is called when the cancellation process is completed successfully, providing the expiration date of the subscription and the storage limit for the free account.
    ///     - expirationDate: The date when the subscription will expire.
    ///     - storageLimit: The storage limit assigned to the free account after the subscription expires.
    ///   - onFailure: A closure that is called when the cancellation process fails. This closure includes another callback for when the user chooses to contact support.
    ///     - onContactSupportTapped: A closure that is invoked when the user requests to contact support.
    ///   - featureFlagProvider: A provider to check feature flags for enabling or disabling specific features related to the cancellation flow.
    ///   - logger: An optional closure for logging debug or error messages during the cancellation flow.
    public init(
        currentSubscription: AccountSubscriptionEntity,
        freeAccountStorageLimit: Int,
        accountUseCase: some AccountUseCaseProtocol,
        currentPlan: PlanEntity,
        assets: CancelAccountPlanAssets,
        navigationController: UINavigationController,
        onSuccess: @escaping (_ expirationDate: Date, _ storageLimit: Int) -> Void,
        onFailure: @escaping ( _ onContactSupportTapped: @escaping () -> Void) -> Void,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.currentSubscription = currentSubscription
        self.freeAccountStorageLimit = freeAccountStorageLimit
        self.accountUseCase = accountUseCase
        self.currentPlan = currentPlan
        self.assets = assets
        self.navigationController = navigationController
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.featureFlagProvider = featureFlagProvider
    }
    
    public func build() -> UIViewController {
        let featureListHelper = FeatureListHelper(
            currentPlan: currentPlan,
            assets: assets
        )
        
        let viewModel = CancelAccountPlanViewModel(
            currentSubscription: currentSubscription,
            featureListHelper: featureListHelper,
            freeAccountStorageLimit: freeAccountStorageLimit,
            achievementUseCase: AchievementUseCase(repo: AchievementRepository.newRepo),
            accountUseCase: accountUseCase,
            tracker: DIContainer.tracker,
            featureFlagProvider: featureFlagProvider,
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
    
    public func dismissCancellationFlow(completion: (() -> Void)?) {
        navigationController?.topViewController?.dismiss(animated: true) { [weak self] in
            self?.navigationController?.popViewController(animated: false)
            completion?()
        }
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
    
    public func showAlert(_ result: CancelSubscriptionResult) {
        switch result {
        case .success(let expirationDate):
            dismissCancellationFlow { [weak self] in
                guard let self else { return }
                onSuccess(expirationDate, freeAccountStorageLimit)
            }
        case .failure:
            onFailure { [weak self] in
                self?.dismissCancellationFlow()
            }
        }
    }
    
    private func openAppleIDSubscriptionsPage() {
        guard let url = appleIDSubscriptionsURL else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
