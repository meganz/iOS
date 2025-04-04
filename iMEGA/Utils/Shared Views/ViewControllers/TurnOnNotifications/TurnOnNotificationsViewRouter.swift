import MEGAAppSDKRepo
import MEGADomain

final class TurnOnNotificationsViewRouter: TurnOnNotificationsViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private weak var vm: TurnOnNotificationsViewModel?
    
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let vm = TurnOnNotificationsViewModel(router: self, accountUseCase: AccountUseCase(repository: AccountRepository.newRepo))
        self.vm = vm
        let vc = TurnOnNotificationsViewController(viewModel: vm)        
        baseViewController = vc
        return vc
    }
    
    func start() {
        let viewController = build()
        guard let viewModel = vm else {
            return
        }
        if viewModel.shouldShowTurnOnNotifications() {
            presenter?.present(viewController, animated: true, completion: nil)
        }
    }
    
    func dismiss() {
        baseViewController?.dismiss(animated: true, completion: nil)
    }
    
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        MEGALinkManager.processLinkURL(settingsURL)
        baseViewController?.dismiss(animated: true, completion: nil)
    }
}
