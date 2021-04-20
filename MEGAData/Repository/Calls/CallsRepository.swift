
extension Result where Success == Void {
    static var success: Result {
        return .success(())
    }
}

final class CallsRepository: NSObject, CallsRepositoryProtocol {

    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()
    private var callbacksDelegate: CallsCallbacksRepositoryProtocol?

    private var callId: MEGAHandle?
    private var call: MEGAChatCall?
    
    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksRepositoryProtocol) {
        if let call = chatSdk.chatCall(forChatId: chatId) {
            self.call = call
            self.callId = call.callId
        }

        chatSdk.add(self)
        self.callbacksDelegate = callbacksDelegate
    }
    
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void) {
        if chatSdk.chatConnectionState(chatId) == .online {
            chatSdk.answerChatCall(chatId, enableVideo: false, enableAudio: true, delegate: MEGAChatAnswerCallRequestDelegate(completion: { [weak self] (error)  in
                if error?.type == .MEGAChatErrorTypeOk {
                    guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                        completion(.failure(.generic))
                        return
                    }
                    self?.call = call
                    self?.callId = call.callId
                    completion(.success(call))
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
    
    func startChatCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void) {
        chatSdk.startChatCall(chatId, enableVideo: enableVideo, enableAudio: true, delegate: MEGAChatStartCallRequestDelegate(completion: { [weak self] (error) in
            if error?.type == .MEGAChatErrorTypeOk {
                guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                    completion(.failure(.generic))
                    return
                }
                self?.call = call
                self?.callId = call.callId
                completion(.success(call))
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
    
    func joinActiveCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void) {
        guard let activeCall = chatSdk.chatCall(forChatId: chatId) else {
            completion(.failure(.generic))
            return
        }
        if activeCall.status == .userNoPresent {
            startChatCall(for: chatId, withVideo: enableVideo, completion: completion)
        } else {
            call = activeCall
            callId = activeCall.callId
            completion(.success(activeCall))
        }
    }
    
    func enableLocalVideo(for chatId: MEGAHandle, delegate: MEGAChatVideoDelegate, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        chatSdk.enableVideo(forChat: chatId, delegate: MEGAChatEnableDisableVideoRequestDelegate(completion: { [weak self] (error) in
            if error?.type == .MEGAChatErrorTypeOk {
                self?.chatSdk.addChatLocalVideo(chatId, delegate: delegate)
                completion(.success)
            } else {
                completion(.failure(.chatLocalVideoNotEnabled))
            }
        }))
    }
    
    func disableLocalVideo(for chatId: MEGAHandle, delegate: MEGAChatVideoDelegate, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        chatSdk.disableVideo(forChat: chatId, delegate: MEGAChatEnableDisableVideoRequestDelegate(completion: { [weak self] (error) in
            if error?.type == .MEGAChatErrorTypeOk {
                self?.chatSdk.addChatLocalVideo(chatId, delegate: delegate)
                completion(.success)
            } else {
                completion(.failure(.chatLocalVideoNotDisabled))
            }
        }))
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
                callbacksDelegate?.createdSession(session, in: chatId)
                break
            case .destroyed:
                callbacksDelegate?.destroyedSession(session)
                break
            default:
                break
            }
        }
        
        if session.hasChanged(.remoteAvFlags) {
            callbacksDelegate?.avFlagsUpdated(for: session)
        }
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk!, call: MEGAChatCall!) {
        if (callId == call.callId) {
            self.call = call;
        } else {
            return;
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
            break
        case .terminatingUserParticipation, .destroyed:
            callbacksDelegate?.callTerminated()
        case .userNoPresent:
            break
//        case .reconnecting:
//            break
        @unknown default:
            fatalError("Call status has an unkown status")
        }
    }
}
