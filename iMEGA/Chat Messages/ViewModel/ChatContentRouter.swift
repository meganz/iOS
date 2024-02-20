import ChatRepo
import MEGADomain
import MEGAPermissions
import MEGAPresentation
import MEGARepo
import MEGASDKRepo

final class ChatContentRouter: ChatContentRouting {
    weak var baseViewController: UIViewController?
    private var chatRoom: ChatRoomEntity
    private var endCallDialog: EndCallDialog?

    init(chatRoom: ChatRoomEntity) {
        self.chatRoom = chatRoom
    }
    
    func build() -> UIViewController? {
        guard let megaChatRoom = chatRoom.toMEGAChatRoom() else {
            return nil
        }
        let chatContentViewModel = ChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession(), callActionManager: CallActionManager.shared)),
            router: self,
            permissionRouter: PermissionAlertRouter.makeRouter(deviceHandler: DevicePermissionsHandler.makeHandler()), 
            analyticsEventUseCase: AnalyticsEventUseCase(repository: AnalyticsRepository.newRepo),
            meetingNoUserJoinedUseCase: MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo)
        )
        
        let chatViewController = ChatViewController(chatRoom: megaChatRoom, chatContentViewModel: chatContentViewModel)
        baseViewController = chatViewController
        return chatViewController
    }
    
    // MARK: - ChatContentRouting
    func startCallUI(chatRoom: ChatRoomEntity, call: CallEntity, isSpeakerEnabled: Bool) {
        guard let baseViewController else { return }
        Task { @MainActor in
            MeetingContainerRouter(presenter: baseViewController,
                                   chatRoom: chatRoom,
                                   call: call,
                                   isSpeakerEnabled: isSpeakerEnabled).start()
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
