import MEGADomain

protocol CallKitManagerProtocol {
    func endCall(_ call: CallEntity)
    func muteUnmuteCall(_ call: CallEntity, muted: Bool)
    func addCallRemoved(handler: @escaping (UUID?) -> Void)
    func removeCallRemovedHandler()
    func notifyStartCallToCallKit(_ call: CallEntity)
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
    
    func notifyStartCallToCallKit(_ call: CallEntity) {
        guard !isCallAlreadyAdded(call), let megaChatCall = call.toMEGAChatCall() else { return }
        
        megaCallManager?.start(megaChatCall)
        megaCallManager?.add(megaChatCall)
    }
    
    // MARK: - Private
    private func isCallAlreadyAdded(_ call: CallEntity) -> Bool {
        guard let megaCallManager = megaCallManager,
              let uuid = megaCallManager.uuid(forChatId: call.chatId, callId: call.callId) else {
            return false
        }
        
        return megaCallManager.callId(for: uuid) != 0
    }
}
