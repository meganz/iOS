import Foundation
import FlexLayout

protocol JoinMegaRouting: Routing {
    func dismiss()
    func createAccount()
}

class JoinMegaRouter: JoinMegaRouting {
    private weak var baseViewController: UIViewController?
    private weak var viewControllerToPresent: UIViewController?
    
    init(viewControllerToPresent: UIViewController) {
        self.viewControllerToPresent = viewControllerToPresent
    }
    
    func build() -> UIViewController {
        let viewModel = JoinMegaViewModel(router: self)
        let vc = JoinMegaViewController(viewModel: viewModel)
        
        baseViewController = vc
        return vc
    }
    
    func start() {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        let nav = MEGANavigationController(rootViewController: build())
        nav.addRightCancelButton()
        viewControllerToPresent.present(nav, animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func createAccount() {
        let createAccountNC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateAccountNavigationControllerID")
        createAccountNC.modalPresentationStyle = .fullScreen
        baseViewController?.present(createAccountNC, animated: true, completion: nil)
    }
    
}
