import MEGADomain

final class MainTabBarCallsRouter: MainTabBarCallsRouting {
    
    private lazy var callWaitingRoomDialog = CallWaitingRoomUsersDialog()
    private var baseViewController: UIViewController

    init(baseViewController: UIViewController) {
        self.baseViewController = baseViewController
    }
    
    func showOneUserWaitingRoomDialog(for username: String, chatName: String, isCallUIVisible: Bool, shouldUpdateDialog: Bool, admitAction: @escaping () -> Void, denyAction: @escaping () -> Void) {
        guard let presenter = baseViewController.presenterViewController() else { return }

        callWaitingRoomDialog.showAlertForOneUser(isCallUIVisible: isCallUIVisible, named: username, chatName: chatName, presenterViewController: presenter, isDialogUpdateMandatory: shouldUpdateDialog) {
            admitAction()
        } denyAction: {
            denyAction()
        }
    }
    
    func showSeveralUsersWaitingRoomDialog(for participantsCount: Int, chatName: String, isCallUIVisible: Bool, shouldUpdateDialog: Bool, admitAction: @escaping () -> Void, seeWaitingRoomAction: @escaping () -> Void) {
        guard let presenter = baseViewController.presenterViewController() else { return }
                        
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
        guard let presenter = baseViewController.presenterViewController() else { return }

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
}
