import MEGADomain

// MARK: - Use case protocol -
protocol CallCoordinatorUseCaseProtocol {
    func endCall(_ call: CallEntity)
    func muteUnmuteCall(_ call: CallEntity, muted: Bool)
    func addCall(_ call: CallEntity)
    func startCall(_ call: CallEntity)
    func answerCall(_ call: CallEntity)
    func addCallRemoved(handler: @escaping (UUID?) -> Void)
    func removeCallRemovedHandler()
}

// MARK: - Use case implementation -
struct CallCoordinatorUseCase: CallCoordinatorUseCaseProtocol {
    
    private var megaCallManager: MEGACallManager? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let callManager = appDelegate.megaCallManager else {
            return nil
        }
        
        return callManager
    }
    
    func addCall(_ call: CallEntity) {
        MEGALogDebug("CallManagerUseCase: Add call called")
        megaCallManager?.addCall(withCallId: call.callId, uuid: call.uuid)
    }
    
    func startCall(_ call: CallEntity) {
        MEGALogDebug("CallManagerUseCase: Start call called")
        megaCallManager?.startCall(withChatId: call.chatId)
    }
    
    func answerCall(_ call: CallEntity) {
        MEGALogDebug("CallManagerUseCase: Answer call called")
        megaCallManager?.answerCall(withChatId: call.chatId)
    }
    
    func endCall(_ call: CallEntity) {
        MEGALogDebug("CallManagerUseCase: End call called")
        let manager = megaCallManager
        manager?.endCall(withCallId: call.callId, chatId: call.chatId)
        manager?.removeCall(by: call.uuid)
    }
    
    func muteUnmuteCall(_ call: CallEntity, muted: Bool) {
        MEGALogDebug("CallManagerUseCase: mute/unmute call called: \(muted)")
        megaCallManager?.muteUnmuteCall(withCallId: call.callId, chatId: call.chatId, muted: muted)
    }
    
    func addCallRemoved(handler: @escaping (UUID?) -> Void) {
        megaCallManager?.addCallRemovedHandler(handler)
    }
    
    func removeCallRemovedHandler() {
        megaCallManager?.removeCallRemovedHandler()
    }
}
