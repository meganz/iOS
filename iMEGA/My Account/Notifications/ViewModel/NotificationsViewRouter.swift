import MEGAPresentation
import Notifications

struct NotificationsViewRouter: Routing {
    private weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func build() -> UIViewController {
        guard let notificationsVC = UIStoryboard(name: "Notifications", bundle: nil).instantiateViewController(withIdentifier: "NotificationsTableViewControllerID") as? NotificationsTableViewController else {
            fatalError("Failed to load NotificationsTableViewController")
        }
        
        let viewModel = NotificationsViewModel(featureFlagProvider: DIContainer.featureFlagProvider)
        notificationsVC.viewModel = viewModel
        return notificationsVC
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
