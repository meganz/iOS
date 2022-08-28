
import Foundation
import UIKit

protocol TermsAndPoliciesRouterProtocol: Routing {
    func didTap(on source: TermsAndPoliciesSource)
}

enum TermsAndPoliciesSource {
    case showPrivacyPolicy
    case showCookiePolicy
    case showTermsOfService
}

final class TermsAndPoliciesRouter: NSObject, TermsAndPoliciesRouterProtocol {
    
    private weak var baseTableViewController: UITableViewController?
    private weak var navigationController: UINavigationController?
    private weak var presentController: UIViewController?

    @objc init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
        
        super.init()
    }
    
    @objc init(presentController: UIViewController?) {
        self.presentController = presentController
        
        super.init()
    }
    
    func build() -> UIViewController {
        guard let termsAndPoliciesTVC = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "TermsAndPoliciesTableViewControllerID") as? TermsAndPoliciesTableViewController else {
            fatalError("Could not instantiate TermsAndPoliciesTableViewController")
        }
        
        let viewModel = TermsAndPoliciesViewModel(router: self)
        termsAndPoliciesTVC.viewModel = viewModel
        termsAndPoliciesTVC.router = self
        
        baseTableViewController = termsAndPoliciesTVC
        
        return termsAndPoliciesTVC
    }
    
    @objc func start() {
        let viewContoller = build()
        if let navigationController = navigationController {
            navigationController.pushViewController(viewContoller, animated: true)
        } else if let presentController = presentController {
            let nav = MEGANavigationController(rootViewController:viewContoller)
            nav.addLeftDismissButton(withText: Strings.Localizable.close)
            presentController.present(nav, animated: true, completion: nil)
        }
    }
    
    func didTap(on source: TermsAndPoliciesSource) {
        let url: URL
        switch source {
        case .showPrivacyPolicy:
            guard let privacyURL = URL(string: "https://mega.nz/privacy") else { return }
            url = privacyURL
            
        case .showCookiePolicy:
            guard let cookieURL = URL(string: "https://mega.nz/cookie") else { return }
            url = cookieURL
            
        case .showTermsOfService:
            guard let termsURL = URL(string: "https://mega.nz/terms") else { return }
            url = termsURL
        }
        
        MEGALinkManager.linkURL = url
        MEGALinkManager.processLinkURL(url)
    }
}
