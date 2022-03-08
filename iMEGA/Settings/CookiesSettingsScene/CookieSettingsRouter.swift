
import Foundation

protocol CookieSettingsRouterProtocol: Routing {
    func didTap(on source: CookieSettingsSource)
}

enum CookieSettingsSource {
    case showCookiePolicy
    case showPrivacyPolicy
}

final class CookieSettingsRouter: NSObject, CookieSettingsRouterProtocol {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private weak var presenter: UIViewController?
    
    @objc init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        guard let cookieSettingsTVC = UIStoryboard(name: "CookieSettings", bundle: nil).instantiateViewController(withIdentifier: "CookieSettingsTableViewControllerID") as? CookieSettingsTableViewController else {
            fatalError("Could not instantiate CookieSettingsTableViewController")
        }
        
        let analyticsUseCase = AnalyticsUseCase(repository: GoogleAnalyticsRepository())

        let viewModel = CookieSettingsViewModel(
            cookieSettingsUseCase: CookieSettingsUseCase(repository: CookieSettingsRepository(sdk:  MEGASdkManager.sharedMEGASdk()), analyticsUseCase: analyticsUseCase),
            router: self
        )
        
        cookieSettingsTVC.router = self
        cookieSettingsTVC.viewModel = viewModel
        
        baseViewController = cookieSettingsTVC
        
        return cookieSettingsTVC
    }
    
    @objc func start() {
        let navigationController = MEGANavigationController(rootViewController: build())
        self.navigationController = navigationController
        
        presenter?.present(navigationController, animated: true, completion: nil)
    }
    
    func didTap(on source: CookieSettingsSource) {
        switch source {
            
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
