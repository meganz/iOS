
protocol CallRepositoryProtocol {
    func startListeningForCallInChat(_ chatId: HandleEntity, callbacksDelegate: CallCallbacksRepositoryProtocol)
    func stopListeningForCall()
    func call(for chatId: HandleEntity) -> CallEntity?
    func answerCall(for chatId: HandleEntity, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func joinCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func hangCall(for callId: HandleEntity)
    func endCall(for callId: HandleEntity)
    func addPeer(toCall call: CallEntity, peerId: UInt64)
    func removePeer(fromCall call: CallEntity, peerId: UInt64)
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64)
    func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64)
    func createActiveSessions()
}

protocol CallCallbacksRepositoryProtocol {
    func createdSession(_ session: ChatSessionEntity, in chatId: HandleEntity)
    func destroyedSession(_ session: ChatSessionEntity, in chatId: HandleEntity)
    func avFlagsUpdated(for session: ChatSessionEntity, in chatId: HandleEntity)
    func audioLevel(for session: ChatSessionEntity, in chatId: HandleEntity)
    func callTerminated(_ call: CallEntity)
    func ownPrivilegeChanged(to privilege: ChatRoomEntity.Privilege, in chatRoom: ChatRoomEntity)
    func participantAdded(with handle: HandleEntity)
    func participantRemoved(with handle: HandleEntity)
    func connecting()
    func inProgress()
    func onHiResSessionChanged(_ session: ChatSessionEntity, in chatId: HandleEntity)
    func onLowResSessionChanged(_ session: ChatSessionEntity, in chatId: HandleEntity)
    func localAvFlagsUpdated(video: Bool, audio: Bool)
    func chatTitleChanged(chatRoom: ChatRoomEntity)
    func networkQualityChanged(_ quality: NetworkQuality)
    func outgoingRingingStopReceived()
}
