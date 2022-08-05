import MEGADomain

final class CallRepository: NSObject, CallRepositoryProtocol {

    private let chatSdk: MEGAChatSdk
    private let callActionManager: CallActionManager
    private var callbacksDelegate: CallCallbacksRepositoryProtocol?

    private var callId: HandleEntity?
    private var call: CallEntity?
    
    init(chatSdk: MEGAChatSdk, callActionManager: CallActionManager) {
        self.chatSdk = chatSdk
        self.callActionManager = callActionManager
    }
    
    func startListeningForCallInChat(_ chatId: HandleEntity, callbacksDelegate: CallCallbacksRepositoryProtocol) {
        if let call = chatSdk.chatCall(forChatId: chatId) {
            self.call = CallEntity(with: call)
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
        return CallEntity(with: chatCall)
    }
    
    func answerCall(for chatId: HandleEntity, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        let delegate = MEGAChatAnswerCallRequestDelegate { [weak self] (error)  in
            if error.type == .MEGAChatErrorTypeOk {
                guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                    completion(.failure(.generic))
                    return
                }
                let callEntity = CallEntity(with: call)
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
        let delegate = MEGAChatStartCallRequestDelegate { [weak self] (error) in
            if error.type == .MEGAChatErrorTypeOk {
                guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                    completion(.failure(.generic))
                    return
                }
                self?.call = CallEntity(with: call)
                self?.callId = call.callId
                completion(.success(CallEntity(with: call)))
            } else {
                switch error.type {
                case .MEGAChatErrorTooMany:
                    completion(.failure(.tooManyParticipants))
                default:
                    completion(.failure(.generic))
                }
            }
        }
        
        callActionManager.startCall(chatId: chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: delegate)
    }
    
    func joinCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        guard let activeCall = chatSdk.chatCall(forChatId: chatId) else {
            completion(.failure(.generic))
            return
        }
        if activeCall.status == .userNoPresent {
            startCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
        } else {
            call = CallEntity(with: activeCall)
            callId = activeCall.callId
            completion(.success(CallEntity(with: activeCall)))
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
}

extension CallRepository: MEGAChatCallDelegate {
    
    func onChatSessionUpdate(_ api: MEGAChatSdk!, chatId: UInt64, callId: UInt64, session: MEGAChatSession!) {
        if self.callId != callId {
            return
        }
                
        if session.hasChanged(.status) {
            switch session.status {
            case .inProgress:
                callbacksDelegate?.createdSession(ChatSessionEntity(with: session), in: chatId)
            case .destroyed:
                callbacksDelegate?.destroyedSession(ChatSessionEntity(with: session), in: chatId)
            default:
                break
            }
        }
        
        if session.status == .inProgress {
            if session.hasChanged(.remoteAvFlags) {
                callbacksDelegate?.avFlagsUpdated(for: ChatSessionEntity(with: session), in: chatId)
            }
            
            if session.hasChanged(.audioLevel) {
                callbacksDelegate?.audioLevel(for: ChatSessionEntity(with: session), in: chatId)
            }
            
            if session.hasChanged(.onHiRes) {
                callbacksDelegate?.onHiResSessionChanged(ChatSessionEntity(with: session), in: chatId)
            }
            
            if session.hasChanged(.onLowRes) {
                callbacksDelegate?.onLowResSessionChanged(ChatSessionEntity(with: session), in: chatId)
            }
        }
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk!, call: MEGAChatCall!) {
        guard callId == call.callId else {
            return
        }
        
        self.call = CallEntity(with: call)
        
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
            callbacksDelegate?.callTerminated(CallEntity(with: call))
        case .userNoPresent:
            break
        @unknown default:
            fatalError("Call status has an unkown status")
        }
    }
}

extension CallRepository: MEGAChatDelegate {
    func onChatListItemUpdate(_ api: MEGAChatSdk!, item: MEGAChatListItem!) {
        guard let chatId = call?.chatId,
              item.chatId == chatId else {
            return
        }
        
        switch item.changes {
        case .ownPrivilege:
            guard let updatedPrivilage = ChatRoomEntity.Privilege(rawValue: item.ownPrivilege.rawValue), let chatRoom = chatSdk.chatRoom(forChatId: chatId) else {
                return
            }
            callbacksDelegate?.ownPrivilegeChanged(to: updatedPrivilage, in: ChatRoomEntity(with: chatRoom))
        case .title:
            guard let chatRoom = chatSdk.chatRoom(forChatId: item.chatId) else { return }
            callbacksDelegate?.chatTitleChanged(chatRoom: ChatRoomEntity(with: chatRoom))
        default:
            break
        }
    }
}
