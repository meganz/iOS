final class CallKitProviderDelegate: NSObject, CXProviderDelegate {
    private weak var callsCoordinator: (any CallsCoordinatorProtocol)?
    private weak var callManager: (any CallManagerProtocol)?
    
    let provider: CXProvider = {
        let providerConfig = CXProviderConfiguration()
        providerConfig.supportsVideo = true
        providerConfig.maximumCallsPerCallGroup = 1
        providerConfig.maximumCallGroups = 1
        providerConfig.supportedHandleTypes = [.generic, .emailAddress]
        providerConfig.iconTemplateImageData = UIImage.megaIconCall.pngData()
        
        return CXProvider(configuration: providerConfig)
    }()

    init(callCoordinator: some CallsCoordinatorProtocol,
         callManager: some CallManagerProtocol) {
        self.callsCoordinator = callCoordinator
        self.callManager = callManager
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    // MARK: - CXProviderDelegate
    func providerDidReset(_ provider: CXProvider) {
        MEGALogDebug("[CallKit] Provider did reset")
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
        Task {
            let success = await callsCoordinator.startCall(callActionSync)
            success ? action.fulfill() : action.fail()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        MEGALogDebug("[CallKit] Provider perform answer call action")
        guard let callsCoordinator, let callManager,
              let callActionSync = callManager.call(forUUID: action.callUUID) else {
            action.fail()
            return
        }
        Task {
            let success = await callsCoordinator.answerCall(callActionSync)
            success ? action.fulfill() : action.fail()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        MEGALogDebug("[CallKit] Provider perform end call action")
        guard let callsCoordinator, let callManager,
              let callActionSync = callManager.call(forUUID: action.callUUID) else {
            action.fail()
            return
        }
        Task {
            let success = await callsCoordinator.endCall(callActionSync)
            success ? action.fulfill() : action.fail()
            callManager.removeCall(withUUID: action.callUUID)
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        MEGALogDebug("[CallKit] Provider perform muted call action")
        guard let callsCoordinator, let callManager,
              let callActionSync = callManager.call(forUUID: action.callUUID) else {
            action.fail()
            return
        }
        Task {
            let success = await callsCoordinator.muteCall(callActionSync)
            success ? action.fulfill() : action.fail()
        }
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        MEGALogDebug("[CallKit] Provider did activate audio session")
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        MEGALogDebug("[CallKit] Provider did deactivate audio session")
    }
}
