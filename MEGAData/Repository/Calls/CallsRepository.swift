
extension Result where Success == Void {
    static var success: Result {
        return .success(())
    }
}

final class CallsRepository: NSObject, CallsRepositoryProtocol {

    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()
    private var callbacksDelegate: CallsCallbacksRepositoryProtocol?

    private var callId: MEGAHandle?
    private var call: CallEntity?
    
    private var isReconnecting: Bool = false
        
    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksRepositoryProtocol) {
        if let call = chatSdk.chatCall(forChatId: chatId) {
            self.call = CallEntity(with: call)
            self.callId = call.callId
        }

        chatSdk.add(self)
        self.callbacksDelegate = callbacksDelegate
    }
    
    func stopListeningForCall() {
        self.call = nil
        self.callId = MEGAInvalidHandle
        chatSdk.remove(self)
        self.callbacksDelegate = nil
    }
    
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void) {
        if chatSdk.chatConnectionState(chatId) == .online {
            chatSdk.answerChatCall(chatId, enableVideo: false, enableAudio: true, delegate: MEGAChatAnswerCallRequestDelegate(completion: { [weak self] (error)  in
                if error?.type == .MEGAChatErrorTypeOk {
                    guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                        completion(.failure(.generic))
                        return
                    }
                    let callEntity = CallEntity(with: call)
                    self?.call = callEntity
                    self?.callId = callEntity.callId
                    completion(.success(callEntity))
                } else {
                    switch error?.type {
                    case .MEGAChatErrorTooMany:
                        completion(.failure(.tooManyParticipants))
                    default:
                        completion(.failure(.generic))
                    }
                }
            }))
        } else {
            completion(.failure(.chatNotConnected))
        }
    }
    
    func startChatCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void) {
        chatSdk.startChatCall(chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: MEGAChatStartCallRequestDelegate(completion: { [weak self] (error) in
            if error?.type == .MEGAChatErrorTypeOk {
                guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                    completion(.failure(.generic))
                    return
                }
                self?.call = CallEntity(with: call)
                self?.callId = call.callId
                completion(.success(CallEntity(with: call)))
            } else {
                switch error?.type {
                case .MEGAChatErrorTooMany:
                    completion(.failure(.tooManyParticipants))
                default:
                    completion(.failure(.generic))
                }
            }
        }))
    }
    
    func joinActiveCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void) {
        guard let activeCall = chatSdk.chatCall(forChatId: chatId) else {
            completion(.failure(.generic))
            return
        }
        if activeCall.status == .userNoPresent {
            startChatCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
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
    
    func hangCall(for callId: MEGAHandle) {
        chatSdk.hangChatCall(callId)
    }
    
    func endCall(for callId: MEGAHandle) {
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
}

extension CallsRepository: MEGAChatCallDelegate {
    
    func onChatSessionUpdate(_ api: MEGAChatSdk!, chatId: UInt64, callId: UInt64, session: MEGAChatSession!) {
        if self.callId != callId {
            return
        }
        
        if session.hasChanged(.status) {
            switch session.status {
            case .inProgress:
                callbacksDelegate?.createdSession(ChatSessionEntity(with: session), in: chatId)
                break
            case .destroyed:
                callbacksDelegate?.destroyedSession(ChatSessionEntity(with: session), in: chatId)
                break
            default:
                break
            }
        }
        
        if session.hasChanged(.remoteAvFlags) {
            callbacksDelegate?.avFlagsUpdated(for: ChatSessionEntity(with: session), in: chatId)
        }
        
        if session.hasChanged(.audioLevel) {
            callbacksDelegate?.audioLevel(for: ChatSessionEntity(with: session), in: chatId)
        }
        
        if session.hasChanged(.onHiRes) {
            callbacksDelegate?.onHiResSession(ChatSessionEntity(with: session), in: chatId)
        }
        
        if session.hasChanged(.onLowRes) {
            callbacksDelegate?.onLowResSession(ChatSessionEntity(with: session), in: chatId)
        }
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk!, call: MEGAChatCall!) {
        if (callId == call.callId) {
            self.call = CallEntity(with: call)
        } else {
            return;
        }
        
        if call.hasChanged(for: .localAVFlags) {
            callbacksDelegate?.localAvFlagsUpdated(video: call.hasLocalVideo, audio: call.hasLocalAudio)
        }
        
        switch call.status {
        case .undefined:
            break
        case .initial:
            break
        case .connecting:
            break
        case .joining:
            break
        case .inProgress:
//            if isReconnecting {
//                isReconnecting = false
//                callbacksDelegate?.reconnected()
//            }
            
            if call.hasChanged(for: .callComposition) {
                switch call.callCompositionChange {
                case .peerAdded:
                    callbacksDelegate?.participantAdded(with: call.peeridCallCompositionChange)
                case .peerRemoved:
                    callbacksDelegate?.participantRemoved(with: call.peeridCallCompositionChange)
                default:
                    break
                }
            }
            break
        case .terminatingUserParticipation, .destroyed:
            callbacksDelegate?.callTerminated()
        case .userNoPresent:
            break
//        case .reconnecting:
//            if !isReconnecting {
//                isReconnecting = true
//                callbacksDelegate?.reconnecting()
//            }
        @unknown default:
            fatalError("Call status has an unkown status")
        }
    }
}
