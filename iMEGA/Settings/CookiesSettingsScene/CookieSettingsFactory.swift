
import Foundation

final class CookieSettingsFactory: NSObject {
    
    @objc func createCookieSettingsNC() -> UINavigationController {
        
        guard let cookieSettingsNC = UIStoryboard(name: "CookieSettings", bundle: nil).instantiateViewController(withIdentifier: "CookieSettingsNavigationControllerID") as? UINavigationController else {
            fatalError("Could not instantiate CookieSettingsNavigationController")
        }
        
        guard let cookieSettingsTVC = cookieSettingsNC.viewControllers.first as? CookieSettingsTableViewController else {
            fatalError("Could not instantiate CookieSettingsTableViewController")
        }
        
        let router = CookieSettingsRouter(navigationController: cookieSettingsNC)
        let viewModel = CookieSettingsViewModel(cookieSettingsUseCase: CookieSettingsUseCase(repository: CookieSettingsRepository(sdk:  MEGASdkManager.sharedMEGASdk())), router: router)
        
        cookieSettingsTVC.router = router
        cookieSettingsTVC.viewModel = viewModel
        
        return cookieSettingsNC
    }
    
    func createThirdPartyCookiesMoreInfoVC() -> UIViewController {
        guard let thirdPartyCookiesMoreInfoVC = UIStoryboard(name: "CookieSettings", bundle: nil).instantiateViewController(withIdentifier: "ThirdPartyCookiesMoreInfoViewControllerID") as? ThirdPartyCookiesMoreInfoViewController else {
            fatalError("Could not instantiate ThirdPartyCookiesMoreInfoViewController")
        }
        
        return thirdPartyCookiesMoreInfoVC
    }
}
