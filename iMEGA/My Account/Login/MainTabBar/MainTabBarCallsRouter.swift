import MEGADomain
import MEGAL10n

final class MainTabBarCallsRouter: MainTabBarCallsRouting {
    
    private lazy var callWaitingRoomDialog = CallWaitingRoomUsersDialog()
    private var screenRecordingAlert: UIAlertController?
    private var baseViewController: UIViewController

    init(baseViewController: UIViewController) {
        self.baseViewController = baseViewController
    }
    
    func showOneUserWaitingRoomDialog(for username: String, chatName: String, isCallUIVisible: Bool, shouldUpdateDialog: Bool, admitAction: @escaping () -> Void, denyAction: @escaping () -> Void) {
        guard screenRecordingAlert == nil, let presenter = baseViewController.presenterViewController() else { return }

        callWaitingRoomDialog.showAlertForOneUser(isCallUIVisible: isCallUIVisible, named: username, chatName: chatName, presenterViewController: presenter, isDialogUpdateMandatory: shouldUpdateDialog) {
            admitAction()
        } denyAction: {
            denyAction()
        }
    }
    
    func showSeveralUsersWaitingRoomDialog(for participantsCount: Int, chatName: String, isCallUIVisible: Bool, shouldUpdateDialog: Bool, admitAction: @escaping () -> Void, seeWaitingRoomAction: @escaping () -> Void) {
        guard screenRecordingAlert == nil, let presenter = baseViewController.presenterViewController() else { return }
                        
        callWaitingRoomDialog.showAlertForSeveralUsers(isCallUIVisible: isCallUIVisible, count: participantsCount, chatName: chatName, presenterViewController: presenter, isDialogUpdateMandatory: shouldUpdateDialog) {
            admitAction()
        } seeWaitingRoomAction: {
            seeWaitingRoomAction()
        }
    }
    
    func dismissWaitingRoomDialog(animated: Bool = true) {
        callWaitingRoomDialog.dismiss(animated: animated)
    }
    
    func showConfirmDenyAction(for username: String, isCallUIVisible: Bool, confirmDenyAction: @escaping () -> Void, cancelDenyAction: @escaping () -> Void) {
        guard screenRecordingAlert == nil, let presenter = baseViewController.presenterViewController() else { return }

        callWaitingRoomDialog.showAlertForConfirmDeny(isCallUIVisible: isCallUIVisible, named: username, presenterViewController: presenter, confirmAction: confirmDenyAction, cancelAction: cancelDenyAction)
    }
    
    func showParticipantsJoinedTheCall(message: String) {
        SVProgressHUD.showSuccess(withStatus: message)
    }
    
    func showWaitingRoomListFor(call: CallEntity, in chatRoom: ChatRoomEntity) {
        let isSpeakerEnabled = AVAudioSession.sharedInstance().isOutputEqualToPortType(.builtInSpeaker)
        MeetingContainerRouter(presenter: baseViewController,
                               chatRoom: chatRoom,
                               call: call,
                               isSpeakerEnabled: isSpeakerEnabled,
                               selectWaitingRoomList: true)
        .start()
    }
    
    func showScreenRecordingAlert(isCallUIVisible: Bool, acceptAction: @escaping () -> Void, learnMoreAction: @escaping () -> Void, leaveCallAction: @escaping () -> Void) {
        guard let presenter = baseViewController.presenterViewController() else { return }

        let alert = UIAlertController(
            title: Strings.Localizable.Calls.ScreenRecording.Alert.title,
            message: Strings.Localizable.Calls.ScreenRecording.Alert.message,
            preferredStyle: .alert
        )
        
        let preferredAction = UIAlertAction(
            title: Strings.Localizable.Calls.ScreenRecording.Alert.Action.accept,
            style: .default
        ) { _ in
            acceptAction()
        }
        
        alert.addAction(preferredAction)
        
        alert.preferredAction = preferredAction
        
        alert.addAction(
            UIAlertAction(
                title: Strings.Localizable.Calls.ScreenRecording.Alert.Action.learnMore,
                style: .default
            ) { _ in
               learnMoreAction()
            }
        )
        
        alert.addAction(
            UIAlertAction(
                title: Strings.Localizable.Calls.ScreenRecording.Alert.Action.leave,
                style: .default
            ) { _ in
                leaveCallAction()
            }
        )
        
        if isCallUIVisible {
            alert.overrideUserInterfaceStyle = .dark
        }

        screenRecordingAlert = alert
        
        presenter.present(alert, animated: true)
    }
    
    func showScreenRecordingNotification(started: Bool, username: String) {
        if started {
            SVProgressHUD.showInfo(withStatus: Strings.Localizable.Calls.ScreenRecording.Notification.Recording.started(username))
        } else {
            SVProgressHUD.showInfo(withStatus: Strings.Localizable.Calls.ScreenRecording.Notification.Recording.stopped(username))
        }
    }
    
    func navigateToPrivacyPolice() {
        if let url = URL(string: "https://mega.io/privacy ") {
            UIApplication.shared.open(url)
        }
    }
    
    func dismissCallUI() {
        guard let meetingContainerViewController = baseViewController.presentedViewController as? MeetingContainerViewController else { return }
        meetingContainerViewController.leaveCallFromScreenRecordingAlert()
    }
}
