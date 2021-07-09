
protocol CallsUseCaseProtocol {
    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksUseCaseProtocol)
    func stopListeningForCall()
    func call(for chatId: MEGAHandle) -> CallEntity?
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void)
    func startOutgoingCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void)
    func joinActiveCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void)
    func createActiveSessions()
    func hangCall(for callId: MEGAHandle)
    func endCall(for callId: MEGAHandle)
    func addPeer(toCall call: CallEntity, peerId: UInt64)
    func removePeer(fromCall call: CallEntity, peerId: UInt64)
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64)
    func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64)
}

protocol CallsCallbacksUseCaseProtocol: AnyObject {
    func attendeeJoined(attendee: CallParticipantEntity)
    func attendeeLeft(attendee: CallParticipantEntity)
    func updateAttendee(_ attendee: CallParticipantEntity)
    func remoteVideoResolutionChanged(for attendee: CallParticipantEntity, with resolution: CallParticipantVideoResolution)
    func audioLevel(for attendee: CallParticipantEntity)
    func callTerminated()
    func ownPrivilegeChanged(to privilege: ChatRoomEntity.Privilege, in chatRoom: ChatRoomEntity)
    func participantAdded(with handle: MEGAHandle)
    func participantRemoved(with handle: MEGAHandle)
    func connecting()
    func inProgress()
    func localAvFlagsUpdated(video: Bool, audio: Bool)
    func chatTitleChanged(chatRoom: ChatRoomEntity)
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
    
    func stopListeningForCall() {
        self.callbacksDelegate = nil
        repository.stopListeningForCall()
    }
    
    func call(for chatId: MEGAHandle) -> CallEntity? {
        repository.call(for: chatId)
    }
    
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void) {
        repository.answerIncomingCall(for: chatId, completion: completion)
    }
    
    func startOutgoingCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void) {
        repository.startChatCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    func joinActiveCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void) {
        repository.joinActiveCall(for: chatId, enableVideo: enableVideo, enableAudio: true, completion: completion)
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
    
    func addPeer(toCall call: CallEntity, peerId: UInt64) {
        repository.addPeer(toCall: call, peerId: peerId)
    }
    
    func removePeer(fromCall call: CallEntity, peerId: UInt64) {
        repository.removePeer(fromCall: call, peerId: peerId)
    }
    
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64) {
        repository.makePeerAModerator(inCall: call, peerId: peerId)
    }
    
    func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64) {
        repository.removePeerAsModerator(inCall: call, peerId: peerId)
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
        callbacksDelegate?.remoteVideoResolutionChanged(for: CallParticipantEntity(session: session, chatId: chatId), with: .high)
    }
    
    func onLowResSession(_ session: ChatSessionEntity, in chatId: MEGAHandle) {
        callbacksDelegate?.remoteVideoResolutionChanged(for: CallParticipantEntity(session: session, chatId: chatId), with: .low)
    }
    
    func localAvFlagsUpdated(video: Bool, audio: Bool) {
        callbacksDelegate?.localAvFlagsUpdated(video: video, audio: audio)
    }
    
    func chatTitleChanged(chatRoom: ChatRoomEntity) {
        callbacksDelegate?.chatTitleChanged(chatRoom: chatRoom)
    }
}
