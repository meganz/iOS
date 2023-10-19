import SwiftUI
import UIKit

public struct OnboardingUpgradeAccountRouter {
    private weak var presenter: UIViewController?
    
    public init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    public func build() -> UIViewController {
        let viewModel = OnboardingUpgradeAccountViewModel()
        let onboardingView = OnboardingUpgradeAccountView(viewModel: viewModel)
        return UIHostingController(rootView: onboardingView)
    }
    
    public func start() {
        let viewController = build()
        viewController.modalPresentationStyle = .fullScreen
        presenter?.present(viewController, animated: true)
    }
}
