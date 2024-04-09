import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI
import UIKit

public final class OnboardingUpgradeAccountRouter {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let accountsConfig: AccountsConfig
    private let viewProPlanAction: () -> Void
    
    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        tracker: some AnalyticsTracking,
        presenter: UIViewController?,
        accountsConfig: AccountsConfig,
        viewProPlanAction: @escaping () -> Void
    ) {
        self.presenter = presenter
        self.purchaseUseCase = purchaseUseCase
        self.tracker = tracker
        self.accountsConfig = accountsConfig
        self.viewProPlanAction = viewProPlanAction
    }
    
    public func build() -> UIViewController {
        let viewModel = OnboardingUpgradeAccountViewModel(
            purchaseUseCase: purchaseUseCase,
            tracker: tracker,
            viewProPlanAction: viewProPlanAction
        )
        
        let onboardingWithViewProPlansView = OnboardingWithViewProPlansView(
            viewModel: viewModel,
            accountsConfig: accountsConfig
        )

        let hostingController = UIHostingController(rootView: onboardingWithViewProPlansView)
        baseViewController = hostingController
        return hostingController
    }
    
    public func start() {
        let viewController = build()
        viewController.modalPresentationStyle = .fullScreen
        presenter?.present(viewController, animated: true)
    }
}
