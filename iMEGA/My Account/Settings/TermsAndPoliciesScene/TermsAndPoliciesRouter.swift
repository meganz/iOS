
import Foundation
import UIKit
import SwiftUI
import Settings
import MEGAPresentation

final class TermsAndPoliciesRouter: NSObject, Routing {
    
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?

    @objc init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
        
        super.init()
    }
    
    func build() -> UIViewController {
        let termsAndPoliciesView = TermsAndPoliciesView(privacyPolicyText: Strings.Localizable.privacyPolicyLabel,
                                                        cookiePolicyText: Strings.Localizable.General.cookiePolicy,
                                                        termsOfServicesText: Strings.Localizable.termsOfServicesLabel)
        let hostingController = UIHostingController(rootView: termsAndPoliciesView)
        baseViewController = hostingController
        baseViewController?.title = Strings.Localizable.Settings.Section.termsAndPolicies
        
        return hostingController
    }
    
    @objc func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
