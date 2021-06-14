import Foundation
import FlexLayout

protocol JoinMegaRouting: Routing {
    func dismiss(completion: (() -> Void)?)
    func createAccount()
}

extension JoinMegaRouting {
    func dismiss() {
        dismiss(completion: nil)
    }
}

class JoinMegaRouter: JoinMegaRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let viewModel = JoinMegaViewModel(router: self)
        let vc = JoinMegaViewController(viewModel: viewModel)
        
        baseViewController = vc
        return vc
    }
    
    func start() {
        let nav = MEGANavigationController(rootViewController: build())
        nav.addRightCancelButton()
        presenter?.present(nav, animated: true)
    }
    
    // MARK: - UI Actions
    func dismiss(completion: (() -> Void)?) {
        baseViewController?.dismiss(animated: true, completion: completion)
    }
    
    func createAccount() {
        dismiss { [weak self] in
            guard let self = self else { return }
            
            if let onboardingViewController = self.presenter as? OnboardingViewController {
                onboardingViewController.presentCreateAccountViewController()
            } else {
                let createAccountNC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateAccountNavigationControllerID")
                self.baseViewController?.present(createAccountNC, animated: true)
            }
        }
    }
    
}
