import MEGADomain
import MEGAPresentation
import Notifications

struct NotificationsViewRouter: Routing {
    private weak var navigationController: UINavigationController?
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    
    init(
        navigationController: UINavigationController?,
        notificationsUseCase: some NotificationsUseCaseProtocol
    ) {
        self.navigationController = navigationController
        self.notificationsUseCase = notificationsUseCase
    }
    
    func build() -> UIViewController {
        guard let notificationsVC = UIStoryboard(name: "Notifications", bundle: nil).instantiateViewController(withIdentifier: "NotificationsTableViewControllerID") as? NotificationsTableViewController else {
            fatalError("Failed to load NotificationsTableViewController")
        }
        
        let viewModel = NotificationsViewModel(
            featureFlagProvider: DIContainer.featureFlagProvider,
            notificationsUseCase: notificationsUseCase
        )
        notificationsVC.viewModel = viewModel
        return notificationsVC
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
