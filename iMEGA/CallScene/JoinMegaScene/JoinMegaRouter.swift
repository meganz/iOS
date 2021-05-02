import Foundation
import FlexLayout

protocol JoinMegaRouting: Routing {
    func dismiss()
    func createAccount()
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
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func createAccount() {
        let createAccountNC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateAccountNavigationControllerID")
        baseViewController?.present(createAccountNC, animated: true, completion: nil)
    }
    
}
