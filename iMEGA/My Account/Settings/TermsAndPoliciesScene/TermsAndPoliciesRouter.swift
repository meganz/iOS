
import Foundation
import UIKit
import SwiftUI

protocol TermsAndPoliciesRouterProtocol: Routing {
    func didTap(on source: TermsAndPoliciesSource)
}

enum TermsAndPoliciesSource {
    case showPrivacyPolicy
    case showCookiePolicy
    case showTermsOfService
}

final class TermsAndPoliciesRouter: NSObject, TermsAndPoliciesRouterProtocol {
    
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?

    @objc init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
        
        super.init()
    }
    
    func build() -> UIViewController {
        let viewModel = TermsAndPoliciesViewModel(router: self)
        let termsAndPoliciesView = TermsAndPoliciesView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: termsAndPoliciesView)
        baseViewController = hostingController
        baseViewController?.title = Strings.Localizable.Settings.Section.termsAndPolicies
        
        return hostingController
    }
    
    @objc func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    func didTap(on source: TermsAndPoliciesSource) {
        let url: URL
        switch source {
        case .showPrivacyPolicy:
            guard let privacyURL = URL(string: "https://mega.io/privacy") else { return }
            url = privacyURL
            
        case .showCookiePolicy:
            guard let cookieURL = URL(string: "https://mega.nz/cookie") else { return }
            url = cookieURL
            
        case .showTermsOfService:
            guard let termsURL = URL(string: "https://mega.io/terms") else { return }
            url = termsURL
        }
        
        MEGALinkManager.linkURL = url
        MEGALinkManager.processLinkURL(url)
    }
}
