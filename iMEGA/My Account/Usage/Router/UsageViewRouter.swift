import MEGAAppPresentation
import MEGADomain

final class UsageViewRouter: Routing {
    private let accountUseCase: any AccountUseCaseProtocol
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private weak var navigationController: UINavigationController?
    private weak var viewController: UIViewController?
    private let hidesBottomBarWhenPushed: Bool

    init(
        accountUseCase: some AccountUseCaseProtocol,
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        navigationController: UINavigationController?,
        hidesBottomBarWhenPushed: Bool = false
    ) {
        self.accountUseCase = accountUseCase
        self.accountStorageUseCase = accountStorageUseCase
        self.navigationController = navigationController
        self.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
    }
    
    func build() -> UIViewController {
        guard let usageVC = UIStoryboard(name: "Usage", bundle: nil).instantiateViewController(withIdentifier: "UsageViewControllerID") as? UsageViewController else {
            return UIViewController()
        }
        
        let viewModel = UsageViewModel(
            accountUseCase: accountUseCase,
            accountStorageUseCase: accountStorageUseCase
        )
        
        usageVC.viewModel = viewModel
        usageVC.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
        viewController = usageVC
        
        return usageVC
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
