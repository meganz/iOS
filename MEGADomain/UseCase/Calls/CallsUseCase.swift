
protocol CallsUseCaseProtocol {

    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksUseCaseProtocol)
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void)
    func startOutgoingCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void)
    func joinActiveCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void)
    func enableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func disableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func videoDeviceSelected() -> String?
    func selectCamera(withLocalizedName localizedName: String)
    func hangCall(for callId: MEGAHandle)
    func endCall(for callId: MEGAHandle)
    func addPeer(toCall call: CallEntity, peerId: UInt64)
    func removePeer(fromCall call: CallEntity, peerId: UInt64)
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64)
}

protocol CallsCallbacksUseCaseProtocol: AnyObject {
    func attendeeJoined(attendee: CallParticipantEntity)
    func attendeeLeft(attendee: CallParticipantEntity)
    func updateAttendee(_ attendee: CallParticipantEntity)
    func callTerminated()
}

final class CallsUseCase: NSObject, CallsUseCaseProtocol {
    
    private let repository: CallsRepositoryProtocol
    private weak var callbacksDelegate: CallsCallbacksUseCaseProtocol?

    init(repository: CallsRepositoryProtocol) {
        self.repository = repository
    }
    
    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksUseCaseProtocol) {
        repository.startListeningForCallInChat(chatId, callbacksDelegate: self)
        self.callbacksDelegate = callbacksDelegate
    }
    
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void) {
        repository.answerIncomingCall(for: chatId, completion: completion)
    }
    
    func startOutgoingCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void) {
        repository.startChatCall(for: chatId, withVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    func joinActiveCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void) {
//        repository.joinActiveCall(for: chatId, withVideo: enableVideo) { [weak self] in
//            switch $0 {
//            case .success(let call):
//                completion(.success(call))
//                if call.sessionsPeerId.size > 0 {
//                    self?.createActiveSessions(for: call)
//                }
//            case .failure(_):
//                completion(.failure(.generic))
//            }
//        }
    }
    
    func enableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        repository.enableLocalVideo(for: chatId, completion: completion)
    }
    
    func disableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        repository.disableLocalVideo(for: chatId, completion: completion)
    }
    
    func videoDeviceSelected() -> String? {
        repository.videoDeviceSelected()
    }
    
    func selectCamera(withLocalizedName localizedName: String) {
        repository.selectCamera(withLocalizedName: localizedName)
    }
    
    func hangCall(for callId: MEGAHandle) {
        repository.hangCall(for: callId)
    }
    
    func endCall(for callId: MEGAHandle) {
        repository.endCall(for: callId)
    }
    
    func addPeer(toCall call: CallEntity, peerId: UInt64) {
        repository.addPeer(toCall: call, peerId: peerId)
    }
    
    func removePeer(fromCall call: CallEntity, peerId: UInt64) {
        repository.removePeer(fromCall: call, peerId: peerId)
    }
    
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64) {
        repository.makePeerAModerator(inCall: call, peerId: peerId)
    }
    
    private func createActiveSessions(for call: CallEntity) {
//        call.sessions?.forEach { createdSession($0, in: call.chatId) }
    }
}

extension CallsUseCase: CallsCallbacksRepositoryProtocol {

    func createdSession(_ session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.attendeeJoined(attendee: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func destroyedSession(_ session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.attendeeLeft(attendee: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func avFlagsUpdated(for session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.updateAttendee(CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func callTerminated() {
        callbacksDelegate?.callTerminated()
    }
}
