
protocol CallsRepositoryProtocol {
    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksRepositoryProtocol)
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void)
    func startChatCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void)
    func joinActiveCall(for chatId: MEGAHandle, withVideo enableVideo: Bool, completion: @escaping (Result<MEGAChatCall, CallsErrorEntity>) -> Void)
    func enableLocalVideo(for chatId: MEGAHandle, delegate: MEGAChatVideoDelegate, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func disableLocalVideo(for chatId: MEGAHandle, delegate: MEGAChatVideoDelegate, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
}

protocol CallsCallbacksRepositoryProtocol {
    func createdSession(_ session: MEGAChatSession, in chatId: MEGAHandle)
    func destroyedSession(_ session: MEGAChatSession)
    func avFlagsUpdated(for session: MEGAChatSession)
    func callTerminated()
}
