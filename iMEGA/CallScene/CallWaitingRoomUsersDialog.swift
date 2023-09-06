import MEGAL10n

final class CallWaitingRoomUsersDialog {
    
    // MARK: - Private properties
    
    private var forceDarkMode: Bool
    private var callWaitingRoomDialogViewController: UIAlertController?
    private var presenter: UIViewController?

    // MARK: - Init
    
    init(forceDarkMode: Bool = false) {
        self.forceDarkMode = forceDarkMode
    }
    
    // MARK: - Interface methods
    
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        callWaitingRoomDialogViewController?.dismiss(animated: animated, completion: completion)
    }
    
    func showAlertForOneUser(named: String,
                             presenterViewController: UIViewController,
                             admitUserAction: @escaping () -> Void,
                             denyAction: @escaping () -> Void) {
        presenter = presenterViewController
        guard callWaitingRoomDialogViewController != nil else {
            prepareAlertForOneUser(named: named, admitUserAction: admitUserAction, denyUserAction: denyAction)
            return
        }
        dismiss(animated: false) { [weak self] in
            self?.prepareAlertForOneUser(named: named, admitUserAction: admitUserAction, denyUserAction: denyAction)
        }
    }
    
    private func prepareAlertForOneUser(named: String,
                                        admitUserAction: @escaping () -> Void,
                                        denyUserAction: @escaping () -> Void) {
        let message = Strings.Localizable.Chat.Call.WaitingRoom.Alert.message(1)
            .replacingOccurrences(of: "[UserName]", with: named)
        let callWaitingRoomDialogViewController = createDialog(message: message,
                                                               admitTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admit,
                                                               denyTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.deny,
                                                               admitAction: admitUserAction,
                                                               denyAction: denyUserAction)
        
        self.callWaitingRoomDialogViewController = callWaitingRoomDialogViewController
        show(callWaitingRoomDialogViewController)
    }
    
    func showAlertForSeveralUsers(count: Int,
                                  presenterViewController: UIViewController,
                                  admitAllAction: @escaping () -> Void,
                                  seeWaitingRoomAction: @escaping () -> Void) {
        presenter = presenterViewController
        guard callWaitingRoomDialogViewController != nil else {
            prepareAlertForSeveralUsers(count: count, admitAllAction: admitAllAction, seeWaitingRoomAction: seeWaitingRoomAction)
            return
        }
        dismiss(animated: false) { [weak self] in
            self?.prepareAlertForSeveralUsers(count: count, admitAllAction: admitAllAction, seeWaitingRoomAction: seeWaitingRoomAction)
        }
    }
    
    private func prepareAlertForSeveralUsers(count: Int,
                                             admitAllAction: @escaping () -> Void,
                                             seeWaitingRoomAction: @escaping () -> Void) {
        let message = Strings.Localizable.Chat.Call.WaitingRoom.Alert.message(count)
        let callWaitingRoomDialogViewController = createDialog(message: message,
                                                               admitTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll,
                                                               denyTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.seeWaitingRoom,
                                                               admitAction: admitAllAction,
                                                               denyAction: seeWaitingRoomAction)
        
        self.callWaitingRoomDialogViewController = callWaitingRoomDialogViewController
        show(callWaitingRoomDialogViewController)
    }
    
    // MARK: - Private methods
    
    private func show(_ alert: UIAlertController, animated: Bool = true) {
        presenter?.present(alert, animated: animated)
    }
    
    private func createDialog(message: String,
                              admitTitle: String,
                              denyTitle: String,
                              admitAction: @escaping () -> Void,
                              denyAction: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: denyTitle,
                style: .default
            ) { _ in
                denyAction()
            }
        )
        
        alert.addAction(
            UIAlertAction(
                title: admitTitle,
                style: .default
            ) { _ in
                admitAction()
            }
        )
        
        return alert
    }
}
