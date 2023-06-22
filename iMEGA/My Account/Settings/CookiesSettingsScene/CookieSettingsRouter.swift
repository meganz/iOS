import Foundation
import MEGAData
import MEGADomain
import MEGAPresentation

protocol CookieSettingsRouting: Routing {
    func didTap(on source: CookieSettingsSource)
}

enum CookieSettingsSource {
    case showCookiePolicy
    case showPrivacyPolicy
}

final class CookieSettingsRouter: NSObject, CookieSettingsRouting {
    private weak var navigationController: UINavigationController?
    private weak var presenter: UIViewController?
    
    @objc init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        guard let cookieSettingsTVC = UIStoryboard(name: "CookieSettings", bundle: nil).instantiateViewController(withIdentifier: "CookieSettingsTableViewControllerID") as? CookieSettingsTableViewController else {
            fatalError("Could not instantiate CookieSettingsTableViewController")
        }

        let viewModel = CookieSettingsViewModel(
            cookieSettingsUseCase: CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo),
            router: self
        )
        
        cookieSettingsTVC.router = self
        cookieSettingsTVC.viewModel = viewModel
        
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
    
    func dismiss() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
