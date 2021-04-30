
protocol CallsRepositoryProtocol {
    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksRepositoryProtocol)
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void)
    func startChatCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void)
    func joinActiveCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallsErrorEntity>) -> Void)
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

protocol CallsCallbacksRepositoryProtocol {
    func createdSession(_ session: ChatSessionEntity, in chatId: MEGAHandle)
    func destroyedSession(_ session: ChatSessionEntity, in chatId: MEGAHandle)
    func avFlagsUpdated(for session: ChatSessionEntity, in chatId: MEGAHandle)
    func callTerminated()
}
