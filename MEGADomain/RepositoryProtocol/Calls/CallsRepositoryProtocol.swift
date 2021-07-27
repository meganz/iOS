
protocol CallsRepositoryProtocol {
    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksRepositoryProtocol)
    func stopListeningForCall()
    func call(for chatId: MEGAHandle) -> CallEntity?
    func answerCall(for chatId: MEGAHandle, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func startCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func joinCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func hangCall(for callId: MEGAHandle)
    func endCall(for callId: MEGAHandle)
    func addPeer(toCall call: CallEntity, peerId: UInt64)
    func removePeer(fromCall call: CallEntity, peerId: UInt64)
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64)
    func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64)
    func createActiveSessions()
}

protocol CallsCallbacksRepositoryProtocol {
    func createdSession(_ session: ChatSessionEntity, in chatId: MEGAHandle)
    func destroyedSession(_ session: ChatSessionEntity, in chatId: MEGAHandle)
    func avFlagsUpdated(for session: ChatSessionEntity, in chatId: MEGAHandle)
    func audioLevel(for session: ChatSessionEntity, in chatId: MEGAHandle)
    func callTerminated()
    func ownPrivilegeChanged(to privilege: ChatRoomEntity.Privilege, in chatRoom: ChatRoomEntity)
    func participantAdded(with handle: MEGAHandle)
    func participantRemoved(with handle: MEGAHandle)
    func connecting()
    func inProgress()
    func onHiResSession(_ session: ChatSessionEntity, in chatId: MEGAHandle)
    func onLowResSession(_ session: ChatSessionEntity, in chatId: MEGAHandle)
    func localAvFlagsUpdated(video: Bool, audio: Bool)
    func chatTitleChanged(chatRoom: ChatRoomEntity)
    func networkQuality()
}
