import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import Settings
import SwiftUI
import UIKit

@MainActor
public protocol OnboardingUpgradeAccountRouting {
    func showTermsAndPolicies()
}

public final class OnboardingUpgradeAccountRouter: OnboardingUpgradeAccountRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let appDomainUseCase: any AppDomainUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let onboardingABvariant: ABTestVariant
    private let accountsConfig: AccountsConfig
    private let isAdsEnabled: Bool
    private let baseStorage: Int
    private let viewProPlanAction: () -> Void
    
    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        appDomainUseCase: some AppDomainUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        onboardingABvariant: ABTestVariant,
        presenter: UIViewController? = nil,
        accountsConfig: AccountsConfig,
        isAdsEnabled: Bool,
        baseStorage: Int,
        viewProPlanAction: @escaping () -> Void
    ) {
        self.presenter = presenter
        self.purchaseUseCase = purchaseUseCase
        self.accountUseCase = accountUseCase
        self.appDomainUseCase = appDomainUseCase
        self.tracker = tracker
        self.onboardingABvariant = onboardingABvariant
        self.accountsConfig = accountsConfig
        self.isAdsEnabled = isAdsEnabled
        self.baseStorage = baseStorage
        self.viewProPlanAction = viewProPlanAction
    }
    
    public func build() -> UIViewController? {
        // Variant A - Show onboarding dialog without the plan list but with button that redirects to Upgrade plan page.
        // Variant B - Show onboarding dialog with complete list of plans.
        // Baseline - Won't be handled on this router. Should show the current Choose your Account Type page.
        switch onboardingABvariant {
        case .baseline: 
            return nil
            
        case .variantA:
            let hostingController = UIHostingController(
                rootView: OnboardingWithViewProPlansView(
                    viewModel: self.onboardingViewModel(),
                    accountsConfig: accountsConfig
                )
            )
            baseViewController = hostingController
            return hostingController
        
        case .variantB:
            let hostingController = UIHostingController(
                rootView: OnboardingWithProPlanListView(
                    viewModel: self.onboardingViewModel(),
                    accountsConfig: accountsConfig
                )
            )
            baseViewController = hostingController
            return hostingController
        }
    }
    
    private func onboardingViewModel() -> OnboardingUpgradeAccountViewModel {
        OnboardingUpgradeAccountViewModel(
            purchaseUseCase: purchaseUseCase,
            accountUseCase: accountUseCase, 
            tracker: tracker,
            isAdsEnabled: isAdsEnabled,
            baseStorage: baseStorage,
            viewProPlanAction: viewProPlanAction,
            router: self
        )
    }

    public func start() {
        guard let viewController = build() else { return }
        viewController.modalPresentationStyle = .fullScreen
        presenter?.present(viewController, animated: true)
    }
    
    public func showTermsAndPolicies() {
        TermsAndPoliciesRouter(
            accountUseCase: accountUseCase,
            appDomainUseCase: appDomainUseCase,
            presenter: baseViewController
        ).start()
    }
}
