
protocol CallUseCaseProtocol {
    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallCallbacksUseCaseProtocol)
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
    func attendeeJoined(attendee: CallParticipantEntity)
    func attendeeLeft(attendee: CallParticipantEntity)
    func updateAttendee(_ attendee: CallParticipantEntity)
    func remoteVideoResolutionChanged(for attendee: CallParticipantEntity)
    func audioLevel(for attendee: CallParticipantEntity)
    func callTerminated()
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
    func audioLevel(for attende: CallParticipantEntity) { }
    func participantAdded(with handle: MEGAHandle) { }
    func participantRemoved(with handle: MEGAHandle) { }
    func connecting() { }
    func inProgress() { }
    func localAvFlagsUpdated(video: Bool, audio: Bool) { }
    func chatTitleChanged(chatRoom: ChatRoomEntity) { }
    func networkQuality() { }
}

final class CallUseCase: NSObject, CallUseCaseProtocol {
    
    private let repository: CallRepositoryProtocol
    private weak var callbacksDelegate: CallCallbacksUseCaseProtocol?

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }
    
    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallCallbacksUseCaseProtocol) {
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
        callbacksDelegate?.attendeeJoined(attendee: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func destroyedSession(_ session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.attendeeLeft(attendee: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func avFlagsUpdated(for session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.updateAttendee(CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func audioLevel(for session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.audioLevel(for: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func callTerminated() {
        callbacksDelegate?.callTerminated()
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
    
    func onHiResSession(_ session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.remoteVideoResolutionChanged(for: CallParticipantEntity(session: session, chatId: chatId))
    }
    
    func onLowResSession(_ session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.remoteVideoResolutionChanged(for: CallParticipantEntity(session: session, chatId: chatId))
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
