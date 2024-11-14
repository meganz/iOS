import MEGADomain
import MEGAPresentation
import MEGASwiftUI
import Notifications

struct NotificationsViewRouter: Routing {
    private weak var navigationController: UINavigationController?
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    private let imageLoader: any ImageLoadingProtocol
    
    init(
        navigationController: UINavigationController?,
        notificationsUseCase: some NotificationsUseCaseProtocol,
        imageLoader: some ImageLoadingProtocol
    ) {
        self.navigationController = navigationController
        self.notificationsUseCase = notificationsUseCase
        self.imageLoader = imageLoader
    }
    
    func build() -> UIViewController {
        guard let notificationsVC = UIStoryboard(name: "Notifications", bundle: nil).instantiateViewController(withIdentifier: "NotificationsTableViewControllerID") as? NotificationsTableViewController else {
            fatalError("Failed to load NotificationsTableViewController")
        }
        
        let viewModel = NotificationsViewModel(
            notificationsUseCase: notificationsUseCase,
            imageLoader: imageLoader,
            tracker: DIContainer.tracker
        )
        notificationsVC.viewModel = viewModel
        return notificationsVC
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
