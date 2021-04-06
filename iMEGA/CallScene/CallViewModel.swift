
protocol CallViewRouting: Routing {
    func dismiss()
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
        case configView(title: String, subtitle: String)
        case switchMenusVisibility
        case switchLayoutMode
        case switchLocalVideo
        case updateName(String)
        case updateDuration(String)
        case showMenuOptions
        case insertParticipant([CallParticipantEntity])
        case deleteParticipantAt(Int, [CallParticipantEntity])
        case updateParticipantAvFlagsAt(Int, [CallParticipantEntity])
    }
    
    private let router: CallViewRouting
    private let callType: CallType
    private var chatRoom: MEGAChatRoom
    private var initialVideoCall: Bool
    private var timer: Timer?
    private var callDurationInfo: CallDurationInfo?
    private var localVideoEnabled = false
    private var callParticipants = [CallParticipantEntity]()

    private let callManagerUseCase: CallManagerUseCaseProtocol
    private let callsUseCase: CallsUseCaseProtocol
    private let userAttributesUseCase: UserAttributesUseCaseProtocol

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    init(router: CallViewRouting, callManager: CallManagerUseCaseProtocol, callsUseCase: CallsUseCaseProtocol, userAttributesUseCase: UserAttributesUseCaseProtocol, chatRoom: MEGAChatRoom, callType: CallType, initialVideoCall: Bool = false) {
        
        self.router = router
        self.callManagerUseCase = callManager
        self.callsUseCase = callsUseCase
        self.userAttributesUseCase = userAttributesUseCase
        self.chatRoom = chatRoom
        self.callType = callType
        self.initialVideoCall = initialVideoCall

        super.init()
    }
    
    private func answerIncomingCall() {
        callsUseCase.answerIncomingCall(for: chatRoom.chatId) { [weak self] in
            switch $0 {
            case .success(let call):
                self?.initDurationTimer(Double(call.duration))
            case .failure(let error):
                switch error {
                case .tooManyParticipants:
                    //show hud with info
                    self?.router.dismiss()
                case .chatNotConnected:
                    //TODO: check why disable video and minimize buttons, and put "connecting" as subtitle
                    break
                default:
                    self?.router.dismiss()
                }
            }
        }
    }
    
    private func startOutgoingCall() {
        callsUseCase.startOutgoingCall(for: chatRoom.chatId, withVideo: initialVideoCall) { [weak self] in
            switch $0 {
            case .success(let call):
                self?.callManagerUseCase.addCall(call)
                self?.callManagerUseCase.startCall(call)
            //TODO: Update UI
            //TODO: Manage AudioSession speaker
            case .failure(_):
                self?.router.dismiss()
            }
        }
    }
    
    private func joinActiveCall() {
        callsUseCase.joinActiveCall(for: chatRoom.chatId, withVideo: initialVideoCall) { [weak self] in
            switch $0 {
            case .success(let call):
                self?.callManagerUseCase.addCall(call)
                self?.callManagerUseCase.startCall(call)
                self?.initDurationTimer(Double(call.duration))
            case .failure(_):
                self?.router.dismiss()
            }
        }
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
    
    private func switchLocalVideo(delegate: MEGAChatVideoDelegate) {
        if localVideoEnabled {
            callsUseCase.disableLocalVideo(for: chatRoom.chatId, delegate: delegate) { [weak self] in
                switch $0 {
                case .success:
                    self?.localVideoEnabled = false
                    self?.invokeCommand?(.switchLocalVideo)
                case .failure(_):
                    //TODO: show error local video HUD
                    MEGALogDebug("Error disabling local video")
                    break
                }
            }
        } else {
            callsUseCase.enableLocalVideo(for: chatRoom.chatId, delegate: delegate) { [weak self] in
                switch $0 {
                case .success:
                    self?.localVideoEnabled = true
                    self?.invokeCommand?(.switchLocalVideo)
                case .failure(_):
                    //TODO: show error local video HUD
                    MEGALogDebug("Error enabling local video")
                    break
                }
            }
        }
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: CallViewAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(title: chatRoom.title ?? "Call default title", subtitle: "time is running!"))
            callsUseCase.startListeningForCallInChat(chatRoom.chatId, callbacksDelegate: self)
            switch callType {
            case .incoming:
                answerIncomingCall()
            case .outgoing:
                startOutgoingCall()
            case .active:
                joinActiveCall()
            @unknown default:
                fatalError()
            }
        case .tapOnView:
            invokeCommand?(.switchMenusVisibility)
        case .tapOnLayoutModeButton:
            break
        case .tapOnOptionsButton:
            break
        case .tapOnBackButton:
            router.dismiss()
        case .switchLocalVideo(let delegate):
            switchLocalVideo(delegate: delegate)
        }
    }
}

struct CallDurationInfo {
    let initDuration: Double
    let baseDate: Date
}

extension CallViewModel: CallsCallbacksUseCaseProtocol {
    func createdSession(_ session: MEGAChatSession, in chatId: MEGAHandle) {
//        let newParticipant = CallParticipantEntity(chatId: chatId, participantId: session.peerId, clientId: session.clientId, networkQuality: session.networkQuality, name: participantName(for: session.peerId))
//        callParticipants.append(newParticipant)
//        invokeCommand?(.insertParticipant(callParticipants))
    }
    
    func destroyedSession(_ session: MEGAChatSession) {
        if let participantToRemove = participant(for: session) {
            guard let index = callParticipants.firstIndex(of: participantToRemove) else { return }
            callParticipants.remove(at: index)
            invokeCommand?(.deleteParticipantAt(index, callParticipants))
        } else {
            MEGALogError("Error remove participant from call")
        }
    }
    
    func avFlagsUpdated(for session: MEGAChatSession) {
        if let participantUpdated = participant(for: session) {
            participantUpdated.video = session.hasVideo ? .on : .off
            participantUpdated.audio = session.hasAudio ? .on : .off
            guard let index = callParticipants.firstIndex(of: participantUpdated) else { return }
            invokeCommand?(.updateParticipantAvFlagsAt(index, callParticipants))
        } else {
            MEGALogError("Error updating av flags participant from call")
        }
    }
    
    func callTerminated() {
        timer?.invalidate()
        //Play hang out sound
        router.dismissAndShowPasscodeIfNeeded()
        //delete call flags?
    }
    
    private func participant(for session: MEGAChatSession) -> CallParticipantEntity? {
        guard let participant = callParticipants.filter({ $0.participantId == session.peerId && $0.clientId == session.clientId }).first else {
            MEGALogError("Error getting participant to remove from call")
            return nil
        }
        return participant
    }
    
    private func participantName(for userHandle: MEGAHandle) -> String? {
        if let displayName = chatRoom.userDisplayName(forUserHandle: userHandle) {
            return displayName
        } else {
            userAttributesUseCase.getUserAttributes(in: chatRoom.chatId, for: NSNumber(value: userHandle)) { [weak self] in
                switch $0 {
                case .success(let chatRoom):
                    self?.chatRoom = chatRoom
                    //TODO: reload participant with obtained name
                case .failure(_):
                    break
                }
            }
            return nil
        }
    }
}

