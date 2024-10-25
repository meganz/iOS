import MEGADomain
import MEGAPresentation
import MEGASDKRepo

protocol RecoveryKeyViewRouting: Routing {
    var recoveryKeyViewController: UIViewController? { get }
    func showSecurityLink()
}

final class RecoveryKeyViewRouter: RecoveryKeyViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    
    private let securityURLLink = NSURL(string: "https://mega.nz/security")
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func build() -> UIViewController {
        guard let viewController = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "MasterKeyViewControllerID") as? MasterKeyViewController else {
            return UIViewController()
        }
        viewController.viewModel = RecoveryKeyViewModel(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            router: self
        )
        baseViewController = viewController
        return viewController
    }
    
    func start() {
        guard let navigationController else {
            MEGALogDebug("[Recovery Key] No UINavigationController passed on RecoveryKeyViewRouter")
            return
        }

        navigationController.pushViewController(build(), animated: true)
    }
    
    var recoveryKeyViewController: UIViewController? {
        baseViewController
    }
    
    func showSecurityLink() {
        securityURLLink?.mnz_presentSafariViewController()
    }
}
