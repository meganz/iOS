final class MainTabBarCallsRouter: MainTabBarCallsRouting {
    
    private lazy var callWaitingRoomDialog = CallWaitingRoomUsersDialog(forceDarkMode: true)
    private var baseViewController: UIViewController

    init(baseViewController: UIViewController) {
        self.baseViewController = baseViewController
    }
    
    func showOneUserWaitingRoomDialog(for username: String, admitAction: @escaping () -> Void, denyAction: @escaping () -> Void) {
        guard let presenter = baseViewController.presenterViewController() else { return }

        callWaitingRoomDialog.showAlertForOneUser(named: username, presenterViewController: presenter) {
            admitAction()
        } denyAction: {
            denyAction()
        }
    }
    
    func showSeveralUsersWaitingRoomDialog(for participantsCount: Int, admitAction: @escaping () -> Void, seeWaitingRoomAction: @escaping () -> Void) {
        guard let presenter = baseViewController.presenterViewController() else { return }
                        
        callWaitingRoomDialog.showAlertForSeveralUsers(count: participantsCount, presenterViewController: presenter) {
            admitAction()
        } seeWaitingRoomAction: {
            seeWaitingRoomAction()
        }
    }
    
    func dismissWaitingRoomDialog(animated: Bool = true) {
        callWaitingRoomDialog.dismiss(animated: animated)
    }
}
