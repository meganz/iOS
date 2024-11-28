import CallKit

struct DefaultCXProviderFactory {
    private var providerConfig: CXProviderConfiguration {
        let providerConfig = CXProviderConfiguration()
        providerConfig.supportsVideo = true
        providerConfig.maximumCallsPerCallGroup = 1
        providerConfig.maximumCallGroups = 1
        providerConfig.supportedHandleTypes = [.generic, .emailAddress]
        providerConfig.iconTemplateImageData = UIImage.megaIconCall.pngData()
        return providerConfig
    }
    func build() -> CXProvider {
        .init(configuration: providerConfig)
    }
}

protocol CallKitProviderDelegateProtocol {
    var provider: CXProvider { get }
}

final class CallKitProviderDelegate: NSObject, CallKitProviderDelegateProtocol, CXProviderDelegate {
    private weak var callsCoordinator: (any CallsCoordinatorProtocol)?
    private weak var callManager: (any CallManagerProtocol)?
    let provider: CXProvider
    
    init(
        callCoordinator: some CallsCoordinatorProtocol,
        callManager: some CallManagerProtocol,
        cxProviderFactory: () -> CXProvider = { DefaultCXProviderFactory().build() }
    ) {
        self.callsCoordinator = callCoordinator
        self.callManager = callManager
        provider = cxProviderFactory()
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    // MARK: - CXProviderDelegate
    func providerDidReset(_ provider: CXProvider) {
        MEGALogDebug("[CallKit] Provider did reset")
        callManager?.removeAllCalls()
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        MEGALogDebug("[CallKit] Provider did begin")
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        MEGALogDebug("[CallKit] Provider perform start call action")
        guard let callsCoordinator, let callManager,
              let callActionSync = callManager.call(forUUID: action.callUUID) else {
            action.fail()
            return
        }
        Task { @MainActor in
            let success = await callsCoordinator.startCall(callActionSync)
            manageActionSuccess(action, success: success)
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        MEGALogDebug("[CallKit] Provider perform answer call action")
        guard let callManager,
              callManager.call(forUUID: action.callUUID) != nil
        else {
            Task { @MainActor in
                if callsCoordinator?.incomingCallForUnknownChat != nil {
                    MEGALogDebug("[CallKit] Provider saving answer call action for a call in a new chat that is not ready yet. It will be answered when chatRoom connectionStatus becomes online")
                    callsCoordinator?.incomingCallForUnknownChat?.answeredCompletion = { [weak self] in
                        self?.answerCall(forAction: action)
                    }
                } else {
                    MEGALogError("[CallKit] Provider fail to answer call because no chat found for incoming call")
                    action.fail()
                }
            }
            return
        }
        answerCall(forAction: action)
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        MEGALogDebug("[CallKit] Provider perform end call action")
        guard let callsCoordinator, let callManager,
              let callActionSync = callManager.call(forUUID: action.callUUID) else {
            action.fail()
            return
        }
        Task { @MainActor in
            let success = await callsCoordinator.endCall(callActionSync)
            success ? action.fulfill() : action.fail()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        MEGALogDebug("[CallKit] Provider perform muted call action - is muted: \(action.isMuted)")
        guard let callsCoordinator, let callManager else {
            action.fail()
            return
        }
        
        callManager.updateCall(withUUID: action.callUUID, muted: action.isMuted)
        
        guard let callActionSync = callManager.call(forUUID: action.callUUID) else {
            action.fail()
            return
        }
        
        Task { @MainActor in
            let success = await callsCoordinator.muteCall(callActionSync)
            success ? action.fulfill() : action.fail()
        }
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        MEGALogDebug("[CallKit] Provider time out performing action \(action)")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        MEGALogDebug("[CallKit] Provider did activate audio session")
        Task { @MainActor in
            callsCoordinator?.configureWebRTCAudioSession()
        }
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        MEGALogDebug("[CallKit] Provider did deactivate audio session")
    }
    
    // MARK: - Private
    @MainActor private func manageActionSuccess(_ action: CXAction, success: Bool) {
        if success {
            callsCoordinator?.disablePassCodeIfNeeded()
            action.fulfill()
        } else {
            action.fail()
        }
    }
    
    private func answerCall(forAction action: CXAnswerCallAction) {
        guard let callsCoordinator,
              let callManager,
              let callActionSync = callManager.call(forUUID: action.callUUID)
        else {
            MEGALogError("[CallKit] Provider perform answer call action fail because coordinator, manager or action sync not found")
            action.fail()
            return
        }
        Task { @MainActor in
            let success = await callsCoordinator.answerCall(callActionSync)
            manageActionSuccess(action, success: success)
        }
    }
}
