
import Foundation

protocol CookieSettingsRouterProtocol {
    func didTap(on source: CookieSettingsSource)
}

enum CookieSettingsSource {
    case showThirdPartyCookiesMoreInfo
    case showCookiePolicy
    case showPrivacyPolicy
}

final class CookieSettingsRouter: NSObject, CookieSettingsRouterProtocol {
    
    private weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        assert(navigationController != nil, "Must pass in a UINavigationController in CookieSettingsRouter.")
        self.navigationController = navigationController
    }
    
    func didTap(on source: CookieSettingsSource) {
        switch source {
        case .showThirdPartyCookiesMoreInfo:
            let thirdPartyCookiesMoreInfoVC = CookieSettingsFactory().createThirdPartyCookiesMoreInfoVC()
            navigationController?.pushViewController(thirdPartyCookiesMoreInfoVC, animated: true)
            
        case .showCookiePolicy:
            NSURL.init(string: "https://mega.nz/cookie")?.mnz_presentSafariViewController()
            
        case .showPrivacyPolicy:
            NSURL.init(string: "https://mega.nz/privacy")?.mnz_presentSafariViewController()
        }
    }
    
    func presentAlert(_ alert: UIAlertController) {
        navigationController?.present(alert, animated: true, completion: nil)
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
