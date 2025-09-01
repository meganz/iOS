import FlexLayout
import Foundation
import MEGAAppPresentation

protocol EncourageGuestUserToJoinMegaRouting: Routing {
    func dismiss(completion: (() -> Void)?)
    func createAccount()
}

extension EncourageGuestUserToJoinMegaRouting {
    func dismiss() {
        dismiss(completion: nil)
    }
}

@objc class EncourageGuestUserToJoinMegaRouter: NSObject, EncourageGuestUserToJoinMegaRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    
    @objc init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let viewModel = EncourageGuestUserToJoinMegaViewModel(router: self)
        let vc = EncourageGuestUserToJoinMegaViewController(viewModel: viewModel)
        
        baseViewController = vc
        return vc
    }
    
    @objc func start() {
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
            guard let self else { return }
            
            if let onboardingViewController = presenter as? OnboardingUSPViewController {
                onboardingViewController.presentSignUpView()
            } else {
                let onboardingViewController = OnboardingUSPViewController()
                onboardingViewController.presentSignUpView()
                baseViewController?.present(onboardingViewController, animated: true)
            }
        }
    }
    
}
