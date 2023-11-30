import MEGADomain
import MEGASDKRepo
import SwiftUI
import UIKit

public struct OnboardingUpgradeAccountRouter {
    private weak var presenter: UIViewController?
    private weak var viewModel: OnboardingUpgradeAccountViewModel?
    private let accountsConfig: AccountsConfig
    
    public init(viewModel: OnboardingUpgradeAccountViewModel, presenter: UIViewController?, accountsConfig: AccountsConfig) {
        self.presenter = presenter
        self.viewModel = viewModel
        self.accountsConfig = accountsConfig
    }
    
    public func build() -> UIViewController {
        guard let viewModel else {
            fatalError("[Onboarding] No viewModel OnboardingUpgradeAccountViewModel")
        }
        let onboardingView = OnboardingWithViewProPlansView(viewModel: viewModel, accountsConfig: accountsConfig)
        return UIHostingController(rootView: onboardingView)
    }
    
    public func start() {
        let viewController = build()
        viewController.modalPresentationStyle = .fullScreen
        presenter?.present(viewController, animated: true)
    }
}
