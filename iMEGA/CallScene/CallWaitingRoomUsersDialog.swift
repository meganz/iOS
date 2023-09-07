import MEGAL10n

final class CallWaitingRoomUsersDialog {
    
    // MARK: - Private properties
    
    private var callWaitingRoomDialogViewController: UIAlertController?
    private var presenter: UIViewController?
    
    // MARK: - Interface methods
    
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        callWaitingRoomDialogViewController?.dismiss(animated: animated, completion: completion)
    }
    
    func showAlertForOneUser(isCallUIVisible: Bool,
                             named: String,
                             chatName: String,
                             presenterViewController: UIViewController,
                             admitUserAction: @escaping () -> Void,
                             denyAction: @escaping () -> Void) {
        presenter = presenterViewController
        guard callWaitingRoomDialogViewController != nil else {
            prepareAlertForOneUser(isCallUIVisible: isCallUIVisible, named: named, chatName: chatName, admitUserAction: admitUserAction, denyUserAction: denyAction)
            return
        }
        dismiss(animated: false) { [weak self] in
            self?.prepareAlertForOneUser(isCallUIVisible: isCallUIVisible, named: named, chatName: chatName, admitUserAction: admitUserAction, denyUserAction: denyAction)
        }
    }
    
    func showAlertForConfirmDeny(isCallUIVisible: Bool,
                                 named: String,
                                 presenterViewController: UIViewController,
                                 confirmAction: @escaping () -> Void) {
        presenter = presenterViewController
        guard callWaitingRoomDialogViewController != nil else {
            prepareAlertForConfirmDeny(isCallUIVisible: isCallUIVisible, named: named, confirmAction: confirmAction)
            return
        }
        dismiss(animated: false) { [weak self] in
            self?.prepareAlertForConfirmDeny(isCallUIVisible: isCallUIVisible, named: named, confirmAction: confirmAction)
        }
    }
    
    func showAlertForSeveralUsers(isCallUIVisible: Bool,
                                  count: Int,
                                  chatName: String,
                                  presenterViewController: UIViewController,
                                  admitAllAction: @escaping () -> Void,
                                  seeWaitingRoomAction: @escaping () -> Void) {
        presenter = presenterViewController
        guard callWaitingRoomDialogViewController != nil else {
            prepareAlertForSeveralUsers(isCallUIVisible: isCallUIVisible, count: count, chatName: chatName, admitAllAction: admitAllAction, seeWaitingRoomAction: seeWaitingRoomAction)
            return
        }
        dismiss(animated: false) { [weak self] in
            self?.prepareAlertForSeveralUsers(isCallUIVisible: isCallUIVisible, count: count, chatName: chatName, admitAllAction: admitAllAction, seeWaitingRoomAction: seeWaitingRoomAction)
        }
    }
    
    // MARK: - Private methods
    
    private func prepareAlertForOneUser(isCallUIVisible: Bool,
                                        named: String,
                                        chatName: String,
                                        admitUserAction: @escaping () -> Void,
                                        denyUserAction: @escaping () -> Void) {
        var message = isCallUIVisible ?
        Strings.Localizable.Chat.Call.WaitingRoom.Alert.message(1) :
        Strings.Localizable.Chat.Call.WaitingRoom.Alert.OutsideCallUI.message(1)
            .replacingOccurrences(of: "[MeetingName]", with: chatName)
    
        message = message
            .replacingOccurrences(of: "[UserName]", with: named)
        
        let callWaitingRoomDialogViewController = createDialog(isCallUIVisible: isCallUIVisible,
                                                               message: message,
                                                               admitTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admit,
                                                               denyTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.deny,
                                                               admitAction: admitUserAction,
                                                               denyAction: denyUserAction)
        
        self.callWaitingRoomDialogViewController = callWaitingRoomDialogViewController
        show(callWaitingRoomDialogViewController)
    }
    
    private func prepareAlertForConfirmDeny(isCallUIVisible: Bool,
                                            named: String,
                                            confirmAction: @escaping () -> Void) {
        let callWaitingRoomDialogViewController = createDialog(isCallUIVisible: isCallUIVisible,
                                                               message: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Message.denyAccess(named),
                                                               admitTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.confirmDeny,
                                                               denyTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.cancel,
                                                               admitAction: confirmAction) { [weak self] in
            self?.dismiss(animated: true)
        }
        
        self.callWaitingRoomDialogViewController = callWaitingRoomDialogViewController
        show(callWaitingRoomDialogViewController)
    }
    
    private func prepareAlertForSeveralUsers(isCallUIVisible: Bool,
                                             count: Int,
                                             chatName: String,
                                             admitAllAction: @escaping () -> Void,
                                             seeWaitingRoomAction: @escaping () -> Void) {
        let message = isCallUIVisible ?
        Strings.Localizable.Chat.Call.WaitingRoom.Alert.message(count) :
        Strings.Localizable.Chat.Call.WaitingRoom.Alert.OutsideCallUI.message(count)
            .replacingOccurrences(of: "[MeetingName]", with: chatName)
        let callWaitingRoomDialogViewController = createDialog(isCallUIVisible: isCallUIVisible,
                                                               message: message,
                                                               admitTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll,
                                                               denyTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.seeWaitingRoom,
                                                               admitAction: admitAllAction,
                                                               denyAction: seeWaitingRoomAction)
        
        self.callWaitingRoomDialogViewController = callWaitingRoomDialogViewController
        show(callWaitingRoomDialogViewController)
    }
    
    private func show(_ alert: UIAlertController, animated: Bool = true) {
        presenter?.present(alert, animated: animated)
    }
    
    private func createDialog(isCallUIVisible: Bool,
                              message: String,
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
        
        if isCallUIVisible {
            alert.overrideUserInterfaceStyle = .dark
        }
        
        return alert
    }
}
