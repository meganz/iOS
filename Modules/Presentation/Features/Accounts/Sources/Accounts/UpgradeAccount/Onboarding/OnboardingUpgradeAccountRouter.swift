import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import Settings
import SwiftUI
import UIKit

public protocol OnboardingUpgradeAccountRouting: Routing {
    func showTermsAndPolicies()
}

public final class OnboardingUpgradeAccountRouter: OnboardingUpgradeAccountRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let accountsConfig: AccountsConfig
    private let viewProPlanAction: () -> Void
    
    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        tracker: some AnalyticsTracking,
        presenter: UIViewController?,
        accountsConfig: AccountsConfig,
        viewProPlanAction: @escaping () -> Void
    ) {
        self.presenter = presenter
        self.purchaseUseCase = purchaseUseCase
        self.accountUseCase = accountUseCase
        self.tracker = tracker
        self.accountsConfig = accountsConfig
        self.viewProPlanAction = viewProPlanAction
    }
    
    public func build() -> UIViewController {
        let viewModel = OnboardingUpgradeAccountViewModel(
            purchaseUseCase: purchaseUseCase,
            accountUseCase: accountUseCase,
            tracker: tracker,
            viewProPlanAction: viewProPlanAction,
            router: self
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
    
    public func showTermsAndPolicies() {
        TermsAndPoliciesRouter(
            accountUseCase: accountUseCase,
            presenter: baseViewController
        ).start()
    }
}
