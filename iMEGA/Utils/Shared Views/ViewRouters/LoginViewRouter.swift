import Combine
import MEGAAppPresentation
import MEGAAuthentication
import MEGAPermissions
import SwiftUI

@MainActor
protocol LoginRouterProtocol: Routing {
    func showSignUp()
    func showLogin()
    func dismiss(completion: (() -> Void)?)
    func showPermissionLoading()
}

final class LoginViewRouter: LoginRouterProtocol {
    private weak var presenter: UIViewController?
    
    init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let routingViewModel = LoginRoutingViewModel(
            router: self)
        let viewController = UIHostingController(
            rootView: LoginView(viewModel: routingViewModel.loginViewModel))
        viewController.modalPresentationStyle = .fullScreen
        return viewController
    }
    
    func start() {
        presenter?.present(build(), animated: true, completion: nil)
    }
    
    func showLogin() {
        start()
    }
    
    func showSignUp() {
        let routingViewModel = CreateAccountRoutingViewModel(
            router: self)
        let viewController = UIHostingController(
            rootView: CreateAccountView(
                viewModel: routingViewModel.createAccountViewModel))
        viewController.modalPresentationStyle = .fullScreen
        presenter?.present(viewController, animated: true, completion: nil)
    }
    
    func dismiss(completion: (() -> Void)?) {
        presenter?.presentedViewController?.dismiss(animated: true, completion: completion)
    }
    
    func showPermissionLoading() {
        PermissionAppLaunchRouter().setRootViewController()
    }
}
