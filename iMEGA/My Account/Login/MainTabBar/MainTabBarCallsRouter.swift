final class MainTabBarCallsRouter: MainTabBarCallsRouting {
    
    private lazy var callWaitingRoomDialog = CallWaitingRoomUsersDialog()
    private var baseViewController: UIViewController

    init(baseViewController: UIViewController) {
        self.baseViewController = baseViewController
    }
    
    func showOneUserWaitingRoomDialog(for username: String, chatName: String, isCallUIVisible: Bool, admitAction: @escaping () -> Void, denyAction: @escaping () -> Void) {
        guard let presenter = baseViewController.presenterViewController() else { return }

        callWaitingRoomDialog.showAlertForOneUser(isCallUIVisible: isCallUIVisible, named: username, chatName: chatName, presenterViewController: presenter) {
            admitAction()
        } denyAction: {
            denyAction()
        }
    }
    
    func showSeveralUsersWaitingRoomDialog(for participantsCount: Int, chatName: String, isCallUIVisible: Bool, admitAction: @escaping () -> Void, seeWaitingRoomAction: @escaping () -> Void) {
        guard let presenter = baseViewController.presenterViewController() else { return }
                        
        callWaitingRoomDialog.showAlertForSeveralUsers(isCallUIVisible: isCallUIVisible, count: participantsCount, chatName: chatName, presenterViewController: presenter) {
            admitAction()
        } seeWaitingRoomAction: {
            seeWaitingRoomAction()
        }
    }
    
    func dismissWaitingRoomDialog(animated: Bool = true) {
        callWaitingRoomDialog.dismiss(animated: animated)
    }
    
    func showConfirmDenyAction(for username: String, isCallUIVisible: Bool, confirmDenyAction: @escaping () -> Void) {
        guard let presenter = baseViewController.presenterViewController() else { return }

        callWaitingRoomDialog.showAlertForConfirmDeny(isCallUIVisible: isCallUIVisible, named: username, presenterViewController: presenter, confirmAction: confirmDenyAction)
    }
}
