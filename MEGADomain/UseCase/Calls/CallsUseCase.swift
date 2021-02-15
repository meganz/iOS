
protocol CallsUseCaseProtocol {

    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksUseCaseProtocol)
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void)
    func startOutgoingCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void)
    func joinActiveCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void)
    func enableLocalVideo(for chatId: MEGAHandle, delegate: MEGAChatVideoDelegate, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func disableLocalVideo(for chatId: MEGAHandle, delegate: MEGAChatVideoDelegate, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
}

protocol CallsCallbacksUseCaseProtocol {
    func createdSession(_ session: MEGAChatSession, in chatId: MEGAHandle)
    func destroyedSession(_ session: MEGAChatSession)
    func avFlagsUpdated(for session: MEGAChatSession)
    func callTerminated()
}

final class CallsUseCase: NSObject, CallsUseCaseProtocol {
    
    private let repository: CallsRepositoryProtocol
    private var callbacksDelegate: CallsCallbacksUseCaseProtocol?

    init(repository: CallsRepositoryProtocol) {
        self.repository = repository
    }
    
    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksUseCaseProtocol) {
        repository.startListeningForCallInChat(chatId, callbacksDelegate: self)
        self.callbacksDelegate = callbacksDelegate
    }
    
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void) {
        repository.answerIncomingCall(for: chatId, completion: completion)
    }
    
    func startOutgoingCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void) {
        repository.startChatCall(for: chatId, withVideo: enableVideo, completion: completion)
    }
    
    func joinActiveCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void) {
        repository.joinActiveCall(for: chatId, withVideo: enableVideo) { [weak self] in
            switch $0 {
            case .success(let call):
                completion(.success(call))
                if call.sessionsPeerId.size > 0 {
                    self?.createActiveSessions(for: call)
                }
            case .failure(_):
                completion(.failure(.generic))
            }
        }
    }
    
    func enableLocalVideo(for chatId: MEGAHandle, delegate: MEGAChatVideoDelegate, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        repository.enableLocalVideo(for: chatId, delegate: delegate, completion: completion)
    }
    
    func disableLocalVideo(for chatId: MEGAHandle, delegate: MEGAChatVideoDelegate, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        repository.disableLocalVideo(for: chatId, delegate: delegate, completion: completion)
    }
    
    private func createActiveSessions(for call: MEGAChatCall) {
        for index in 0...call.sessionsPeerId.size - 1 {
            if let session = call.session(forPeer: call.sessionsPeerId.megaHandle(at: index), clientId: call.sessionsClientId.megaHandle(at: index)) {
                createdSession(session, in: call.chatId)
            }
        }
    }
}

extension CallsUseCase: CallsCallbacksRepositoryProtocol {

    func createdSession(_ session: MEGAChatSession, in chatId: MEGAHandle) {
        callbacksDelegate?.createdSession(session, in: chatId)
    }
    
    func destroyedSession(_ session: MEGAChatSession) {
        callbacksDelegate?.destroyedSession(session)
    }
    
    func avFlagsUpdated(for session: MEGAChatSession) {
        callbacksDelegate?.avFlagsUpdated(for: session)
    }
    
    func callTerminated() {
        callbacksDelegate?.callTerminated()
    }
}
