import MEGADomain
import MEGAPresentation

final class UsageViewRouter: Routing {
    private let accountUseCase: any AccountUseCaseProtocol
    private weak var navigationController: UINavigationController?
    private weak var viewController: UIViewController?
    
    init(
        accountUseCase: some AccountUseCaseProtocol,
        navigationController: UINavigationController?
    ) {
        self.accountUseCase = accountUseCase
        self.navigationController = navigationController
    }
    
    func build() -> UIViewController {
        guard let usageVC = UIStoryboard(name: "Usage", bundle: nil).instantiateViewController(withIdentifier: "UsageViewControllerID") as? UsageViewController else {
            return UIViewController()
        }
        
        let viewModel = UsageViewModel(accountUseCase: accountUseCase)
        
        usageVC.viewModel = viewModel
        viewController = usageVC
        
        return usageVC
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
