
protocol CallUseCaseProtocol {
    func startListeningForCallInChat<T: CallCallbacksUseCaseProtocol>(_ chatId: MEGAHandle, callbacksDelegate: T)
    func stopListeningForCall()
    func call(for chatId: MEGAHandle) -> CallEntity?
    func answerCall(for chatId: MEGAHandle, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func startCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func joinCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func createActiveSessions()
    func hangCall(for callId: MEGAHandle)
    func endCall(for callId: MEGAHandle)
    func addPeer(toCall call: CallEntity, peerId: MEGAHandle)
    func removePeer(fromCall call: CallEntity, peerId: MEGAHandle)
    func makePeerAModerator(inCall call: CallEntity, peerId: MEGAHandle)
    func removePeerAsModerator(inCall call: CallEntity, peerId: MEGAHandle)
}

protocol CallCallbacksUseCaseProtocol: AnyObject {
    func participantJoined(participant: CallParticipantEntity)
    func participantLeft(participant: CallParticipantEntity)
    func updateParticipant(_ participant: CallParticipantEntity)
    func remoteVideoResolutionChanged(for participant: CallParticipantEntity)
    func highResolutionChanged(for participant: CallParticipantEntity)
    func lowResolutionChanged(for participant: CallParticipantEntity)
    func audioLevel(for participant: CallParticipantEntity)
    func callTerminated(_ call: CallEntity)
    func ownPrivilegeChanged(to privilege: ChatRoomEntity.Privilege, in chatRoom: ChatRoomEntity)
    func participantAdded(with handle: MEGAHandle)
    func participantRemoved(with handle: MEGAHandle)
    func connecting()
    func inProgress()
    func localAvFlagsUpdated(video: Bool, audio: Bool)
    func chatTitleChanged(chatRoom: ChatRoomEntity)
    func networkQuality()
}

//Default implementation for optional callbacks
extension CallCallbacksUseCaseProtocol {
    func remoteVideoResolutionChanged(for attende: CallParticipantEntity) { }
    func highResolutionChanged(for participant: CallParticipantEntity) { }
    func lowResolutionChanged(for participant: CallParticipantEntity) { }
    func audioLevel(for attende: CallParticipantEntity) { }
    func callTerminated(_ call: CallEntity) { }
    func participantAdded(with handle: MEGAHandle) { }
    func participantRemoved(with handle: MEGAHandle) { }
    func connecting() { }
    func inProgress() { }
    func localAvFlagsUpdated(video: Bool, audio: Bool) { }
    func chatTitleChanged(chatRoom: ChatRoomEntity) { }
    func networkQuality() { }
}

final class CallUseCase<T: CallRepositoryProtocol>: NSObject, CallUseCaseProtocol {
    
    private let repository: T
    private weak var callbacksDelegate: CallCallbacksUseCaseProtocol?

    init(repository: T) {
        self.repository = repository
    }
    
    func startListeningForCallInChat<T: CallCallbacksUseCaseProtocol>(_ chatId: MEGAHandle, callbacksDelegate: T) {
        repository.startListeningForCallInChat(chatId, callbacksDelegate: self)
        self.callbacksDelegate = callbacksDelegate
    }
    
    func stopListeningForCall() {
        self.callbacksDelegate = nil
        repository.stopListeningForCall()
    }
    
    func call(for chatId: MEGAHandle) -> CallEntity? {
        repository.call(for: chatId)
    }
    
    func answerCall(for chatId: MEGAHandle, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        repository.answerCall(for: chatId, completion: completion)
    }
    
    func startCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        repository.startCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    func joinCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        repository.joinCall(for: chatId, enableVideo: enableVideo, enableAudio: true, completion: completion)
    }
    
    func createActiveSessions() {
        repository.createActiveSessions()
    }
    
    func hangCall(for callId: MEGAHandle) {
        repository.hangCall(for: callId)
    }
    
    func endCall(for callId: MEGAHandle) {
        repository.endCall(for: callId)
    }
    
    func addPeer(toCall call: CallEntity, peerId: MEGAHandle) {
        repository.addPeer(toCall: call, peerId: peerId)
    }
    
    func removePeer(fromCall call: CallEntity, peerId: MEGAHandle) {
        repository.removePeer(fromCall: call, peerId: peerId)
    }
    
    func makePeerAModerator(inCall call: CallEntity, peerId: MEGAHandle) {
        repository.makePeerAModerator(inCall: call, peerId: peerId)
    }
    
    func removePeerAsModerator(inCall call: CallEntity, peerId: MEGAHandle) {
        repository.removePeerAsModerator(inCall: call, peerId: peerId)
    }
}

extension CallUseCase: CallCallbacksRepositoryProtocol {

    func createdSession(_ session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.participantJoined(participant: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func destroyedSession(_ session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.participantLeft(participant: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func avFlagsUpdated(for session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.updateParticipant(CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func audioLevel(for session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.audioLevel(for: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func callTerminated(_ call: CallEntity) {
        callbacksDelegate?.callTerminated(call)
    }
    
    func ownPrivilegeChanged(to privilege: ChatRoomEntity.Privilege, in chatRoom: ChatRoomEntity) {
        callbacksDelegate?.ownPrivilegeChanged(to: privilege, in: chatRoom)
    }
    
    func participantAdded(with handle: MEGAHandle) {
        callbacksDelegate?.participantAdded(with: handle)
    }
    
    func participantRemoved(with handle: MEGAHandle) {
        callbacksDelegate?.participantRemoved(with: handle)
    }
    
    func connecting() {
        callbacksDelegate?.connecting()
    }
    
    func inProgress() {
        callbacksDelegate?.inProgress()
    }
    
    func onHiResSessionChanged(_ session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.highResolutionChanged(for: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func onLowResSessionChanged(_ session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.lowResolutionChanged(for: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func localAvFlagsUpdated(video: Bool, audio: Bool) {
        callbacksDelegate?.localAvFlagsUpdated(video: video, audio: audio)
    }
    
    func chatTitleChanged(chatRoom: ChatRoomEntity) {
        callbacksDelegate?.chatTitleChanged(chatRoom: chatRoom)
    }
    
    func networkQuality() {
        callbacksDelegate?.networkQuality()
    }
}
