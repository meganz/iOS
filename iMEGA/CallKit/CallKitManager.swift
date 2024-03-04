import MEGADomain

protocol CallKitManagerProtocol {
    func endCall(_ call: CallEntity)
    func muteUnmuteCall(_ call: CallEntity, muted: Bool)
    func addCallRemoved(handler: @escaping (UUID?) -> Void)
    func removeCallRemovedHandler()
}

struct CallKitManager: CallKitManagerProtocol {
    
    private var megaCallManager: MEGACallManager? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let callManager = appDelegate.megaCallManager else {
            return nil
        }
        
        return callManager
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
