import MEGADomain
import Combine

final class CallRepository: NSObject, CallRepositoryProtocol {

    private let chatSdk: MEGAChatSdk
    private let callActionManager: CallActionManager
    private var callbacksDelegate: (any CallCallbacksRepositoryProtocol)?

    private var callId: HandleEntity?
    private var call: CallEntity?
    
    private var callUpdateListeners = [CallUpdateListener]()

    init(chatSdk: MEGAChatSdk, callActionManager: CallActionManager) {
        self.chatSdk = chatSdk
        self.callActionManager = callActionManager
    }
    
    func startListeningForCallInChat(_ chatId: HandleEntity, callbacksDelegate: any CallCallbacksRepositoryProtocol) {
        if let call = chatSdk.chatCall(forChatId: chatId) {
            self.call = call.toCallEntity()
            self.callId = call.callId
        }

        chatSdk.add(self as MEGAChatCallDelegate)
        chatSdk.add(self as MEGAChatDelegate)
        self.callbacksDelegate = callbacksDelegate
    }
    
    func stopListeningForCall() {
        chatSdk.remove(self as MEGAChatCallDelegate)
        chatSdk.remove(self as MEGAChatDelegate)
        self.call = nil
        self.callId = MEGAInvalidHandle
        self.callbacksDelegate = nil
    }
    
    func call(for chatId: HandleEntity) -> CallEntity? {
        guard let chatCall = chatSdk.chatCall(forChatId: chatId) else { return nil }
        return chatCall.toCallEntity()
    }
    
    func answerCall(for chatId: HandleEntity, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        let delegate = MEGAChatAnswerCallRequestDelegate { [weak self] (error)  in
            if error.type == .MEGAChatErrorTypeOk {
                guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                    completion(.failure(.generic))
                    return
                }
                let callEntity = call.toCallEntity()
                self?.call = callEntity
                self?.callId = callEntity.callId
                completion(.success(callEntity))
            } else {
                switch error.type {
                case .MEGAChatErrorTooMany:
                    completion(.failure(.tooManyParticipants))
                default:
                    completion(.failure(.generic))
                }
            }
        }
        
        callActionManager.answerCall(chatId: chatId, enableVideo: false, enableAudio: true, delegate: delegate)
    }
    
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        let delegate = createStartMeetingRequestDelegate(for: chatId, completion: completion)
        
        callActionManager.startCall(chatId: chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: delegate)
    }
    
    @MainActor
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await withCheckedThrowingContinuation { continuation in
            startCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio) { result in
                switch result {
                case .success(let callEntity):
                    continuation.resume(returning: callEntity)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        let delegate = createStartMeetingRequestDelegate(for: scheduledMeeting.chatId, completion: completion)
        
        callActionManager.startCallNoRinging(chatId: scheduledMeeting.chatId, scheduledId: scheduledMeeting.scheduledId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: delegate)
    }
    
    @MainActor
    func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await withCheckedThrowingContinuation { continuation in
            startCallNoRinging(for: scheduledMeeting, enableVideo: enableVideo, enableAudio: enableAudio) { result in
                switch result {
                case .success(let callEntity):
                    continuation.resume(returning: callEntity)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func joinCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        guard let activeCall = chatSdk.chatCall(forChatId: chatId) else {
            completion(.failure(.generic))
            return
        }
        if activeCall.status == .userNoPresent {
            startCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
        } else {
            call = activeCall.toCallEntity()
            callId = activeCall.callId
            completion(.success(activeCall.toCallEntity()))
        }
    }
    
    func createActiveSessions() {
        guard let call = call, !call.clientSessions.isEmpty else {
            return
        }
        call.clientSessions.forEach {
            callbacksDelegate?.createdSession($0, in: call.chatId)
        }
    }
    
    func hangCall(for callId: HandleEntity) {
        chatSdk.hangChatCall(callId)
    }
    
    func endCall(for callId: HandleEntity) {
        chatSdk.endChatCall(callId)
    }
    
    func addPeer(toCall call: CallEntity, peerId: UInt64) {
        chatSdk.invite(toChat: call.chatId, user: peerId, privilege: MEGAChatRoomPrivilege.standard.rawValue)
    }
    
    func removePeer(fromCall call: CallEntity, peerId: UInt64) {
        chatSdk.remove(fromChat: call.chatId, userHandle: peerId)
    }
    
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64) {
        chatSdk.updateChatPermissions(call.chatId, userHandle: peerId, privilege: MEGAChatRoomPrivilege.moderator.rawValue)
    }
    
    func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64) {
        chatSdk.updateChatPermissions(call.chatId, userHandle: peerId, privilege: MEGAChatRoomPrivilege.standard.rawValue)
    }
    
    func localAvFlagsChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        callUpdateListener(forCallId: callId, change: .localAVFlags)
            .monitor
            .eraseToAnyPublisher()
    }
    
    func callStatusChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        callUpdateListener(forCallId: callId, change: .status)
            .monitor
            .eraseToAnyPublisher()
    }

    private func callUpdateListener(forCallId callId: HandleEntity, change: CallEntity.ChangeType) -> CallUpdateListener {
        guard let callUpdateListener = callUpdateListeners.filter({ $0.callId == callId && change == $0.changeType }).first else {
            let callUpdateListener = CallUpdateListener(sdk: chatSdk, callId: callId, changeType: change)
            callUpdateListeners.append(callUpdateListener)
            return callUpdateListener
        }

        return callUpdateListener
    }
    
    private func createStartMeetingRequestDelegate(for chatId: ChatIdEntity, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) -> MEGAChatStartCallRequestDelegate {
        return MEGAChatStartCallRequestDelegate { [weak self] (error) in
            if error.type == .MEGAChatErrorTypeOk {
                guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                    completion(.failure(.generic))
                    return
                }
                self?.call = call.toCallEntity()
                self?.callId = call.callId
                completion(.success(call.toCallEntity()))
            } else {
                switch error.type {
                case .MEGAChatErrorTooMany:
                    completion(.failure(.tooManyParticipants))
                default:
                    completion(.failure(.generic))
                }
            }
        }
    }
}

private final class CallUpdateListener: NSObject, MEGAChatCallDelegate {
    private let sdk: MEGAChatSdk
    let changeType: CallEntity.ChangeType
    let callId: HandleEntity
    
    private let source = PassthroughSubject<CallEntity, Never>()
    
    var monitor: AnyPublisher<CallEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk, callId: HandleEntity, changeType: CallEntity.ChangeType) {
        self.sdk = sdk
        self.changeType = changeType
        self.callId = callId
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        guard call.callId == callId, call.changes.toChangeTypeEntity() == changeType else {
            return
        }
        source.send(call.toCallEntity())
    }
}

extension CallRepository: MEGAChatCallDelegate {
    
    func onChatSessionUpdate(_ api: MEGAChatSdk, chatId: UInt64, callId: UInt64, session: MEGAChatSession) {
        if self.callId != callId {
            return
        }
                
        if session.hasChanged(.status) {
            switch session.status {
            case .inProgress:
                callbacksDelegate?.createdSession(session.toChatSessionEntity(), in: chatId)
            case .destroyed:
                callbacksDelegate?.destroyedSession(session.toChatSessionEntity(), in: chatId)
            default:
                break
            }
        }
        
        if session.status == .inProgress {
            if session.hasChanged(.remoteAvFlags) {
                callbacksDelegate?.avFlagsUpdated(for: session.toChatSessionEntity(), in: chatId)
            }
            
            if session.hasChanged(.audioLevel) {
                callbacksDelegate?.audioLevel(for: session.toChatSessionEntity(), in: chatId)
            }
            
            if session.hasChanged(.onHiRes) {
                callbacksDelegate?.onHiResSessionChanged(session.toChatSessionEntity(), in: chatId)
            }
            
            if session.hasChanged(.onLowRes) {
                callbacksDelegate?.onLowResSessionChanged(session.toChatSessionEntity(), in: chatId)
            }
        }
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        guard callId == call.callId else {
            return
        }
        
        self.call = call.toCallEntity()
        
        if call.hasChanged(for: .localAVFlags) {
            callbacksDelegate?.localAvFlagsUpdated(video: call.hasLocalVideo, audio: call.hasLocalAudio)
        }
        
        if call.hasChanged(for: .networkQuality) {
            switch call.networkQuality {
            case .bad:
                callbacksDelegate?.networkQualityChanged(.bad)
            case .good:
                callbacksDelegate?.networkQualityChanged(.good)
            @unknown default:
                MEGALogDebug("Call network quality has an unkown status")
            }
        }
        
        if call.hasChanged(for: .outgoingRingingStop) {
            callbacksDelegate?.outgoingRingingStopReceived()
        }
        
        switch call.status {
        case .undefined:
            break
        case .initial:
            break
        case .connecting:
            callbacksDelegate?.connecting()
        case .joining:
            break
        case .inProgress:
            if call.hasChanged(for: .status) {
                callbacksDelegate?.inProgress()
            }
            
            if call.hasChanged(for: .callComposition) {
                if call.peeridCallCompositionChange == chatSdk.myUserHandle {
                    return
                }
                switch call.callCompositionChange {
                case .peerAdded:
                    callbacksDelegate?.participantAdded(with: call.peeridCallCompositionChange)
                case .peerRemoved:
                    callbacksDelegate?.participantRemoved(with: call.peeridCallCompositionChange)
                default:
                    break
                }
            }
        case .terminatingUserParticipation, .destroyed:
            callbacksDelegate?.callTerminated(call.toCallEntity())
        case .userNoPresent:
            break
        @unknown default:
            fatalError("Call status has an unkown status")
        }
    }
}

extension CallRepository: MEGAChatDelegate {
    func onChatListItemUpdate(_ api: MEGAChatSdk, item: MEGAChatListItem) {
        guard let chatId = call?.chatId,
              item.chatId == chatId else {
            return
        }
        
        switch item.changes {
        case .ownPrivilege:
            guard let chatRoom = chatSdk.chatRoom(forChatId: chatId) else {
                return
            }
            callbacksDelegate?.ownPrivilegeChanged(to: item.ownPrivilege.toOwnPrivilegeEntity(), in: chatRoom.toChatRoomEntity())
        case .title:
            guard let chatRoom = chatSdk.chatRoom(forChatId: item.chatId) else { return }
            callbacksDelegate?.chatTitleChanged(chatRoom: chatRoom.toChatRoomEntity())
        default:
            break
        }
    }
}
