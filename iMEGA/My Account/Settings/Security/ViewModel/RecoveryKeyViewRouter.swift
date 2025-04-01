import MEGAAppPresentation
import MEGADomain
import MEGASDKRepo

protocol RecoveryKeyViewRouting: Routing {
    var recoveryKeyViewController: UIViewController? { get }
    func showSecurityLink()
    func presentView()
}

final class RecoveryKeyViewRouter: RecoveryKeyViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private weak var presenter: UIViewController?
    private let saveMasterKeyCompletion: (() -> Void)?
    
    private let securityURLLink = NSURL(string: "https://mega.nz/security")
    
    init(
        navigationController: UINavigationController? = nil,
        presenter: UIViewController? = nil,
        saveMasterKeyCompletion: (() -> Void)? = nil
    ) {
        self.navigationController = navigationController
        self.presenter = presenter
        self.saveMasterKeyCompletion = saveMasterKeyCompletion
    }
    
    func build() -> UIViewController {
        guard let viewController = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "MasterKeyViewControllerID") as? MasterKeyViewController else {
            return UIViewController()
        }
        viewController.viewModel = RecoveryKeyViewModel(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            saveMasterKeyCompletion: saveMasterKeyCompletion,
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
    
    func presentView() {
        guard let presenter else {
            MEGALogDebug("[Recovery Key] No presenter UIViewController passed on RecoveryKeyViewRouter")
            return
        }
        
        let navigationController = MEGANavigationController(rootViewController: build())
        navigationController.addRightCancelButton()
        presenter.present(navigationController, animated: true)
    }
    
    var recoveryKeyViewController: UIViewController? {
        baseViewController
    }
    
    func showSecurityLink() {
        securityURLLink?.mnz_presentSafariViewController()
    }
}
