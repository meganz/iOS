
protocol CallViewRouting: Routing {
    func dismissAndShowPasscodeIfNeeded()
}

enum CallViewAction: ActionType {
    case onViewReady
    case tapOnView
    case tapOnLayoutModeButton
    case tapOnOptionsButton
    case tapOnBackButton
    case switchLocalVideo(delegate: MEGAChatVideoDelegate)
}

final class CallViewModel: NSObject, ViewModelType {
    enum Command: CommandType {
        case configView(title: String, subtitle: String, isVideoEnabled: Bool)
        case switchMenusVisibility
        case switchLayoutMode
        case switchLocalVideo(on: Bool)
        case updateName(String)
        case updateDuration(String)
        case showMenuOptions
        case insertParticipant([CallParticipantEntity])
        case deleteParticipantAt(Int, [CallParticipantEntity])
        case updateParticipantAvFlagsAt(Int, [CallParticipantEntity])
        case updatedCameraPosition(position: CameraPosition)
    }
    
    private let router: CallViewRouting
    private var chatRoom: ChatRoomEntity
    private var initialVideoCall: Bool
    private var timer: Timer?
    private var callDurationInfo: CallDurationInfo?
    private var callParticipants = [CallParticipantEntity]()
    private weak var containerViewModel: MeetingContainerViewModel?

    private let callManagerUseCase: CallManagerUseCaseProtocol
    private let callsUseCase: CallsUseCaseProtocol
    private let captureDeviceUseCase: CaptureDeviceUseCaseProtocol
    private let userAttributesUseCase: UserAttributesUseCaseProtocol

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    init(router: CallViewRouting, containerViewModel: MeetingContainerViewModel, callManager: CallManagerUseCaseProtocol, callsUseCase: CallsUseCaseProtocol, userAttributesUseCase: UserAttributesUseCaseProtocol, captureDeviceUseCase: CaptureDeviceUseCaseProtocol, chatRoom: ChatRoomEntity, initialVideoCall: Bool = false) {
        
        self.router = router
        self.containerViewModel = containerViewModel
        self.callManagerUseCase = callManager
        self.callsUseCase = callsUseCase
        self.userAttributesUseCase = userAttributesUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.chatRoom = chatRoom
        self.initialVideoCall = initialVideoCall

        super.init()
        
        addDelegate()
    }
    
    deinit {
        removeDelegate()
        callsUseCase.stopListeningForCall()
    }
    
    private func initDurationTimer(_ duration: Double) {
        if timer == nil {
            let callDurationInfo = CallDurationInfo(initDuration: duration, baseDate: Date())
            let timer = Timer(timeInterval: 1, repeats: true, block: { [weak self] (timer) in
                let duration = Date().timeIntervalSince1970 - callDurationInfo.baseDate.timeIntervalSince1970 + callDurationInfo.initDuration
                self?.invokeCommand?(.updateDuration(NSString.mnz_string(fromTimeInterval: duration)))
            })
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: CallViewAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(title: chatRoom.title ?? "Call default title", subtitle: "time is running!", isVideoEnabled: initialVideoCall))
            callsUseCase.startListeningForCallInChat(chatRoom.chatId, callbacksDelegate: self)
        case .tapOnView:
            invokeCommand?(.switchMenusVisibility)
            containerViewModel?.dispatch(.changeMenuVisibility)
        case .tapOnLayoutModeButton:
            break
        case .tapOnOptionsButton:
            break
        case .tapOnBackButton:
            containerViewModel?.dispatch(.tapOnBackButton)
        case .switchLocalVideo(let delegate):
            addVideo(delegate: delegate)
        }
    }
}

struct CallDurationInfo {
    let initDuration: Double
    let baseDate: Date
}

extension CallViewModel: CallsCallbacksUseCaseProtocol {
    
    func attendeeJoined(attendee: CallParticipantEntity) {
        callParticipants.append(attendee)
        invokeCommand?(.insertParticipant(callParticipants))
    }
    
    func attendeeLeft(attendee: CallParticipantEntity) {
        if let index = callParticipants.firstIndex(of: attendee) {
            callParticipants.remove(at: index)
            invokeCommand?(.deleteParticipantAt(index, callParticipants))
        }
    }
    
    func updateAttendee(_ attendee: CallParticipantEntity) {
        guard let index = callParticipants.firstIndex(of: attendee) else { return }
        invokeCommand?(.updateParticipantAvFlagsAt(index, callParticipants))
    }
    
    func callTerminated() {
        timer?.invalidate()
        //Play hang out sound
        router.dismissAndShowPasscodeIfNeeded()
        //delete call flags?
    }
    
    private func participant(for session: ChatSessionEntity) -> CallParticipantEntity? {
        guard let participant = callParticipants.filter({ $0.participantId == session.peerId && $0.clientId == session.clientId }).first else {
            MEGALogError("Error getting participant to remove from call")
            return nil
        }
        return participant
    }
    
    private func participantName(for userHandle: MEGAHandle) -> String? {
        if let displayName = name(for: userHandle) {
            return displayName
        } else {
//            userAttributesUseCase.getUserAttributes(in: chatRoom.chatId, for: NSNumber(value: userHandle)) { [weak self] in
//                switch $0 {
//                case .success(let chatRoom):
//                    self?.chatRoom = chatRoom
//                    //TODO: reload participant with obtained name
//                case .failure(_):
//                    break
//                }
//            }
            return nil
        }
    }
    
    //TODO: Refactor the below method
    func name(for handle: UInt64) -> String? {
        let user = MEGAStore.shareInstance().fetchUser(withUserHandle: handle)

        if let userName = user?.displayName,
            userName.count > 0 {
            return userName
        }

        return MEGASdkManager.sharedMEGAChatSdk().userFullnameFromCache(byUserHandle: handle)
    }
    
    private func isBackCameraSelected() -> Bool {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(postion: .back),
              callsUseCase.videoDeviceSelected() == selectCameraLocalizedString else {
            return false
        }
        
        return true
    }

}

//TODO: Refactor the below extension
extension CallViewModel: MEGAChatRequestDelegate {
    func addDelegate() {
        MEGASdkManager.sharedMEGAChatSdk().add(self)
    }
    
    func removeDelegate() {
        MEGASdkManager.sharedMEGAChatSdk().remove(self)
    }
    
    func onChatRequestFinish(_ api: MEGAChatSdk!, request: MEGAChatRequest!, error: MEGAChatError!) {
        if request.type == .disableAudioVideoCall {
            invokeCommand?(.switchLocalVideo(on: request.isFlag))
        }
        
        if request.type == .changeVideoStream || request.type == . disableAudioVideoCall {
            invokeCommand?(.updatedCameraPosition(position: isBackCameraSelected() ? .back : .front))
        }
    }
    
    func addVideo(delegate: MEGAChatVideoDelegate) {
        MEGASdkManager.sharedMEGAChatSdk().addChatLocalVideo(chatRoom.chatId, delegate: delegate)
    }
    
    func removeVideo(delegate: MEGAChatVideoDelegate) {
        MEGASdkManager.sharedMEGAChatSdk().removeChatLocalVideo(chatRoom.chatId, delegate: delegate)
    }
}

