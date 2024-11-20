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
                             isDialogUpdateMandatory: Bool,
                             shouldBlockAddingUsersToCall: Bool,
                             admitUserAction: @escaping () -> Void,
                             denyAction: @escaping () -> Void) {
        presenter = presenterViewController
        guard shouldUpdateDialog(mandatory: isDialogUpdateMandatory) else { return }
        playSoundIfNeeded()
        
        let presentAlert: () -> Void = { [weak self] in
            self?.prepareAlertForOneUser(
                isCallUIVisible: isCallUIVisible,
                named: named,
                chatName: chatName,
                shouldBlockAddingUsersToCall: shouldBlockAddingUsersToCall,
                admitUserAction: admitUserAction,
                denyUserAction: denyAction
            )
        }
        
        presentImmediatelyOrAfterDismissingPreviousOne(presentAlert)
    }
    
    private func presentImmediatelyOrAfterDismissingPreviousOne(_ presentAlert: @escaping () -> Void) {
        guard callWaitingRoomDialogViewController != nil else {
            presentAlert()
            return
        }
        dismiss(animated: false) {
            presentAlert()
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
                                  isDialogUpdateMandatory: Bool,
                                  shouldBlockAddingUsersToCall: Bool,
                                  admitAllAction: @escaping () -> Void,
                                  seeWaitingRoomAction: @escaping () -> Void) {
        presenter = presenterViewController
        guard shouldUpdateDialog(mandatory: isDialogUpdateMandatory) else { return }
        playSoundIfNeeded()
        let prepareAlert: () -> Void = { [weak self] in
            self?.prepareAlertForSeveralUsers(
                isCallUIVisible: isCallUIVisible,
                count: count,
                chatName: chatName,
                shouldBlockAddingUsersToCall: shouldBlockAddingUsersToCall,
                admitAllAction: admitAllAction,
                seeWaitingRoomAction: seeWaitingRoomAction
            )
        }
        presentImmediatelyOrAfterDismissingPreviousOne(prepareAlert)
    }
    
    // MARK: - Private methods
    
    private func prepareAlertForOneUser(isCallUIVisible: Bool,
                                        named: String,
                                        chatName: String,
                                        shouldBlockAddingUsersToCall: Bool,
                                        admitUserAction: @escaping () -> Void,
                                        denyUserAction: @escaping () -> Void) {
        
        let copy = singleUserTitleAndMessage(
            isCallUIVisible: isCallUIVisible,
            named: named,
            chatName: chatName,
            shouldBlockAddingUsersToCall: shouldBlockAddingUsersToCall
        )
        
        let alert =  UIAlertController.createAlert(
            forceDarkMode: isCallUIVisible,
            title: copy.title,
            message: copy.message,
            preferredActionTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admit,
            secondaryActionTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.deny,
            preferredActionEnabled: !shouldBlockAddingUsersToCall,
            preferredAction: admitUserAction,
            secondaryAction: denyUserAction
        )
        
        self.callWaitingRoomDialogViewController = alert
        show(alert)
    }
    
    private func singleUserTitleAndMessage(
        isCallUIVisible: Bool,
        named: String,
        chatName: String,
        shouldBlockAddingUsersToCall: Bool
    ) -> (title: String?, message: String) {
        var descriptionWhoWantsToJoin = isCallUIVisible ?
        Strings.Localizable.Chat.Call.WaitingRoom.Alert.message(1) :
        Strings.Localizable.Chat.Call.WaitingRoom.Alert.OutsideCallUI.message(1)
            .replacingOccurrences(of: "[MeetingName]", with: chatName)
        
        descriptionWhoWantsToJoin = descriptionWhoWantsToJoin
            .replacingOccurrences(of: "[UserName]", with: named)
        if shouldBlockAddingUsersToCall {
            return (title: descriptionWhoWantsToJoin, message: Strings.Localizable.Meetings.Warning.overParticipantLimit)
        } else {
            return (title: nil, message: descriptionWhoWantsToJoin)
        }
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
    
    private func severalUsersCopy(
        isCallUIVisible: Bool,
        count: Int,
        chatName: String,
        shouldBlockAddingUsersToCall: Bool
    ) -> (title: String?, message: String) {
        let descriptionWhoWantsToJoin = isCallUIVisible ?
        Strings.Localizable.Chat.Call.WaitingRoom.Alert.message(count) :
        Strings.Localizable.Chat.Call.WaitingRoom.Alert.OutsideCallUI.message(count)
            .replacingOccurrences(of: "[MeetingName]", with: chatName)
        if shouldBlockAddingUsersToCall {
            return (
                title: descriptionWhoWantsToJoin,
                message: Strings.Localizable.Meetings.Warning.overParticipantLimit
            )
        } else {
            return (
                title: nil,
                message: descriptionWhoWantsToJoin
            )
        }
    }
    
    private func prepareAlertForSeveralUsers(
        isCallUIVisible: Bool,
        count: Int,
        chatName: String,
        shouldBlockAddingUsersToCall: Bool,
        admitAllAction: @escaping () -> Void,
        seeWaitingRoomAction: @escaping () -> Void
    ) {
        let copy = severalUsersCopy(
            isCallUIVisible: isCallUIVisible,
            count: count,
            chatName: chatName,
            shouldBlockAddingUsersToCall: shouldBlockAddingUsersToCall
        )
        let alert = UIAlertController.createAlert(
            forceDarkMode: isCallUIVisible,
            title: copy.title,
            message: copy.message,
            preferredActionTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll,
            secondaryActionTitle: Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.seeWaitingRoom,
            preferredActionEnabled: !shouldBlockAddingUsersToCall,
            preferredAction: admitAllAction,
            secondaryAction: seeWaitingRoomAction
        )
        
        self.callWaitingRoomDialogViewController = alert
        
        show(
            alert
        )
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
    
    private func shouldUpdateDialog(mandatory: Bool) -> Bool {
        guard !mandatory else {
            return true
        }
        
        return presenter?.presentedViewController == callWaitingRoomDialogViewController
    }
}
