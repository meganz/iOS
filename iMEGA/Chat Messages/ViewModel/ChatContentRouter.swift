import ChatRepo
import MEGADomain
import MEGAPermissions
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import MEGAUI

enum ChatContentRoutingStyle {
    case push
    case present
}

@objc final class ChatContentRouter: NSObject, ChatContentRouting {
    weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private let chatContentRoutingStyle: ChatContentRoutingStyle
    private let chatRoom: ChatRoomEntity
    private let publicLink: String?
    private let showShareLinkViewAfterOpenChat: Bool
    private var endCallDialog: EndCallDialog?
    private let tracker: any AnalyticsTracking

    init(
        chatRoom: ChatRoomEntity,
        presenter: UIViewController?,
        publicLink: String? = nil,
        showShareLinkViewAfterOpenChat: Bool = false,
        chatContentRoutingStyle: ChatContentRoutingStyle = .push,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.chatRoom = chatRoom
        self.presenter = presenter
        self.publicLink = publicLink
        self.showShareLinkViewAfterOpenChat = showShareLinkViewAfterOpenChat
        self.chatContentRoutingStyle = chatContentRoutingStyle
        self.tracker = tracker
    }
    
    @objc init(
        chatRoom: MEGAChatRoom,
        presenter: UIViewController?,
        publicLink: String?,
        showShareLinkViewAfterOpenChat: Bool
    ) {
        self.chatRoom = chatRoom.toChatRoomEntity()
        self.presenter = presenter
        self.publicLink = publicLink
        self.showShareLinkViewAfterOpenChat = showShareLinkViewAfterOpenChat
        self.chatContentRoutingStyle = .push
        self.tracker = DIContainer.tracker
    }
    
    @objc static func chatViewController(
        for chatRoom: MEGAChatRoom
    ) -> ChatViewController? {
        guard let chatViewController = ChatContentRouter(
            chatRoom: chatRoom.toChatRoomEntity(),
            presenter: nil,
            tracker: DIContainer.tracker
        ).build() as? ChatViewController else { return nil }
        return chatViewController
    }
    
    func build() -> UIViewController {
        guard let presenter else {
            return UIViewController()
        }
        let chatContentViewModel = ChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession())),
            router: self,
            permissionRouter: PermissionAlertRouter.makeRouter(deviceHandler: DevicePermissionsHandler.makeHandler()), 
            analyticsEventUseCase: AnalyticsEventUseCase(repository: AnalyticsRepository.newRepo),
            meetingNoUserJoinedUseCase: MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo),
            handleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo),
            callManager: CallKitCallManager.shared
        )
        
        let chatViewController = ChatViewController(chatRoom: chatRoom, chatContentViewModel: chatContentViewModel, photoPicker: MEGAPhotoPicker(presenter: presenter))
        if let publicLink {
            chatViewController.publicChatWithLinkCreated = showShareLinkViewAfterOpenChat
            chatViewController.publicChatLink = URL(string: publicLink)
        }
        
        baseViewController = chatViewController
        return chatViewController
    }
    
    @objc func start() {
        let chatViewController = build()
        switch chatContentRoutingStyle {
        case .push:
            guard let navigationPresenter = presenter as? UINavigationController else { return }
            navigationPresenter.pushViewController(chatViewController, animated: true)
        case .present:
            presenter?.present(MEGANavigationController(rootViewController: chatViewController), animated: true)
        }
    }
    
    // MARK: - ChatContentRouting
    func startCallUI(chatRoom: ChatRoomEntity, call: CallEntity, isSpeakerEnabled: Bool) {
        guard let baseViewController else { return }
        Task { @MainActor in
            MeetingContainerRouter(
                presenter: baseViewController,
                chatRoom: chatRoom,
                call: call,
                tracker: tracker
            ).start()
        }
    }
    
    func openWaitingRoom(scheduledMeeting: ScheduledMeetingEntity) {
        guard let baseViewController else { return }
        Task { @MainActor in
            WaitingRoomViewRouter(presenter: baseViewController, scheduledMeeting: scheduledMeeting).start()
        }
    }
    
    func showCallAlreadyInProgress(endAndJoinAlertHandler: (() -> Void)?) {
        guard let baseViewController else { return }
        MeetingAlreadyExistsAlert.show(presenter: baseViewController, endAndJoinAlertHandler: endAndJoinAlertHandler)
    }
    
    func showEndCallDialog(stayOnCallCompletion: @escaping () -> Void, endCallCompletion: @escaping () -> Void) {
        let endCallDialog = EndCallDialog(stayOnCallAction: stayOnCallCompletion, endCallAction: endCallCompletion)

        self.endCallDialog = endCallDialog
        Task { @MainActor in
            endCallDialog.show()
        }
    }
    
    func removeEndCallDialogIfNeeded() {
        guard let endCallDialog = endCallDialog else { return }
        Task { @MainActor in
            endCallDialog.dismiss()
            self.endCallDialog = nil
        }
    }
}
