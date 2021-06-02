// MARK: - Use case protocol -
protocol CallManagerUseCaseProtocol {
    func endCall(_ call: CallEntity)
    func muteUnmuteCall(_ call: CallEntity, muted: Bool)
    func addCall(_ call: CallEntity)
    func startCall(_ call: CallEntity)
}

// MARK: - Use case implementation -
struct CallManagerUseCase: CallManagerUseCaseProtocol {
    
    let megaCallManager: MEGACallManager

    init(megaCallManager: MEGACallManager = (UIApplication.shared.delegate as! AppDelegate).megaCallManager!) {
        self.megaCallManager = megaCallManager
    }

    func addCall(_ call: CallEntity) {
        megaCallManager.addCall(withCallId: call.callId, uuid: call.uuid)
    }
    
    func startCall(_ call: CallEntity) {
        megaCallManager.startCall(withChatId: call.chatId)
    }
    
    func endCall(_ call: CallEntity) {
        megaCallManager.endCall(withCallId: call.callId, chatId: call.chatId)
        megaCallManager.removeCall(by: call.uuid)
    }
    
    func muteUnmuteCall(_ call: CallEntity, muted: Bool) {
        megaCallManager.muteUnmuteCall(withCallId: call.callId, chatId: call.chatId, muted: muted)
    }
}
