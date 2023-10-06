import MEGAL10n

final class CallWaitingRoomUsersDialog {
    
    // MARK: - Private properties
    
    private var callWaitingRoomDialogViewController: UIAlertController?
    private var presenter: UIViewController?
    private let tonePlayer = TonePlayer()

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
        playSoundIfNeeded()
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
                                 confirmAction: @escaping () -> Void,
                                 cancelAction: @escaping () -> Void) {
        presenter = presenterViewController
        guard callWaitingRoomDialogViewController != nil else {
            prepareAlertForConfirmDeny(isCallUIVisible: isCallUIVisible, named: named, confirmAction: confirmAction, cancelAction: cancelAction)
            return
        }
        dismiss(animated: false) { [weak self] in
            self?.prepareAlertForConfirmDeny(isCallUIVisible: isCallUIVisible, named: named, confirmAction: confirmAction, cancelAction: cancelAction)
        }
    }
    
    func showAlertForSeveralUsers(isCallUIVisible: Bool,
                                  count: Int,
                                  chatName: String,
                                  presenterViewController: UIViewController,
                                  admitAllAction: @escaping () -> Void,
                                  seeWaitingRoomAction: @escaping () -> Void) {
        presenter = presenterViewController
        playSoundIfNeeded()
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
        
        let callWaitingRoomDialogViewController =  UIAlertController.createAlert(forceDarkMode: isCallUIVisible,
                                                                                  message: message,
                                                                                  preferredActionTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admit,
                                                                                  secondaryActionTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.deny,
                                                                                  preferredAction: admitUserAction,
                                                                                  secondaryAction: denyUserAction)
        
        self.callWaitingRoomDialogViewController = callWaitingRoomDialogViewController
        show(callWaitingRoomDialogViewController)
    }
    
    private func prepareAlertForConfirmDeny(isCallUIVisible: Bool,
                                            named: String,
                                            confirmAction: @escaping () -> Void,
                                            cancelAction: @escaping () -> Void) {
        let callWaitingRoomDialogViewController =  UIAlertController.createAlert(forceDarkMode: isCallUIVisible,
                                                                                  message: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Message.denyAccess(named),
                                                                                  preferredActionTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.confirmDeny,
                                                                                  secondaryActionTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.cancel,
                                                                                 showNotNowAction: false,
                                                                                  preferredAction: confirmAction,
                                                                                  secondaryAction: cancelAction)
        
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
        let callWaitingRoomDialogViewController = UIAlertController.createAlert(forceDarkMode: isCallUIVisible,
                                                                                 message: message,
                                                                                 preferredActionTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll,
                                                                                 secondaryActionTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.seeWaitingRoom,
                                                                                 preferredAction: admitAllAction,
                                                                                 secondaryAction: seeWaitingRoomAction)
        
        self.callWaitingRoomDialogViewController = callWaitingRoomDialogViewController
        show(callWaitingRoomDialogViewController)
    }
    
    private func show(_ alert: UIAlertController, animated: Bool = true) {
        presenter?.present(alert, animated: animated)
    }
    
    private func playSoundIfNeeded() {
        guard presenter?.presentedViewController != callWaitingRoomDialogViewController else {
            return
        }
        tonePlayer.play(tone: .waitingRoomEvent)
    }
}
