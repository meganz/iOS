import CallKit
import MEGAAssets

struct DefaultCXProviderFactory {
    private var providerConfig: CXProviderConfiguration {
        let providerConfig = CXProviderConfiguration()
        providerConfig.supportsVideo = true
        providerConfig.maximumCallsPerCallGroup = 1
        providerConfig.maximumCallGroups = 1
        providerConfig.supportedHandleTypes = [.generic, .emailAddress]
        providerConfig.iconTemplateImageData = MEGAAssets.UIImage.megaIconCall.pngData()
        return providerConfig
    }
    func build() -> CXProvider {
        .init(configuration: providerConfig)
    }
}

protocol CallKitProviderDelegateProviding {
    func build(
        callCoordinator: any CallsCoordinatorProtocol,
        callsManager: any CallsManagerProtocol
    ) -> any CallKitProviderDelegateProtocol
}

struct CallKitProviderDelegateProvider: CallKitProviderDelegateProviding {
    func build(
        callCoordinator: any CallsCoordinatorProtocol,
        callsManager: any CallsManagerProtocol
    ) -> any CallKitProviderDelegateProtocol {
        CallKitProviderDelegate(
            callCoordinator: callCoordinator,
            callsManager: callsManager,
            callUpdateFactory: .defaultFactory
        )
    }
}

protocol CallKitProviderDelegateProtocol {
    func reportOutgoingCallStartedConnecting(with uuid: UUID)
    func reportOutgoingCallConnected(with uuid: UUID)
    func updateCallTitle(_ title: String, for callUUID: UUID)
    func updateCallVideo(_ video: Bool, for callUUID: UUID)
    func reportNewIncomingCall(with uuid: UUID, title: String, completion: @escaping (Bool) -> Void)
    func reportEndedCall(with uuid: UUID, reason: EndCallReason)
}

final class CallKitProviderDelegate: NSObject, CallKitProviderDelegateProtocol, CXProviderDelegate {
    func reportOutgoingCallStartedConnecting(with uuid: UUID) {
        provider.reportOutgoingCall(with: uuid, startedConnectingAt: nil)
    }
    
    func reportOutgoingCallConnected(with uuid: UUID) {
        provider.reportOutgoingCall(with: uuid, connectedAt: nil)
    }
    
    func updateCallTitle(_ title: String, for callUUID: UUID) {
        provider.reportCall(with: callUUID, updated: callUpdateFactory.callUpdate(withChatTitle: title))
    }
    
    func updateCallVideo(_ video: Bool, for callUUID: UUID) {
        provider.reportCall(with: callUUID, updated: callUpdateFactory.callUpdate(withVideo: video))
    }
    
    func reportNewIncomingCall(with uuid: UUID, title: String, completion: @escaping (Bool) -> Void) {
        let update = callUpdateFactory.createCallUpdate(title: title)
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error {
                CrashlyticsLogger.log("[CallKit] Provider Error reporting incoming call: \(String(describing: error))")
                MEGALogError("[CallKit] Provider Error reporting incoming call: \(String(describing: error))")
                if (error as NSError?)?.code == CXErrorCodeIncomingCallError.Code.filteredByDoNotDisturb.rawValue {
                    MEGALogDebug("[CallKit] Do not disturb enabled")
                }
            }
            completion(error == nil)
        }
    }
    
    func reportEndedCall(with uuid: UUID, reason: EndCallReason) {
        MEGALogDebug("[CallKit] Report end call reason \(reason)")
        provider.reportCall(
            with: uuid,
            endedAt: nil,
            reason: CXCallEndedReason(rawValue: reason.rawValue) ?? .failed
        )
    }

    private weak var callsCoordinator: (any CallsCoordinatorProtocol)?
    private let callsManager: any CallsManagerProtocol
    let provider: CXProvider
    let callUpdateFactory: CXCallUpdateFactory

    init(
        callCoordinator: some CallsCoordinatorProtocol,
        callsManager: some CallsManagerProtocol,
        cxProviderFactory: () -> CXProvider = { DefaultCXProviderFactory().build() },
        callUpdateFactory: CXCallUpdateFactory
    ) {
        self.callsCoordinator = callCoordinator
        self.callsManager = callsManager
        provider = cxProviderFactory()
        self.callUpdateFactory = callUpdateFactory
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    // MARK: - CXProviderDelegate
    func providerDidReset(_ provider: CXProvider) {
        MEGALogDebug("[CallKit] Provider did reset")
        callsManager.removeAllCalls()
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        MEGALogDebug("[CallKit] Provider did begin")
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        MEGALogDebug("[CallKit] Provider perform start call action")
        guard let callsCoordinator,
              let callActionSync = callsManager.call(forUUID: action.callUUID) else {
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
        guard callsManager.call(forUUID: action.callUUID) != nil
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
        guard let callsCoordinator,
              let callActionSync = callsManager.call(forUUID: action.callUUID) else {
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
        guard let callsCoordinator else {
            action.fail()
            return
        }
        
        callsManager.updateCall(withUUID: action.callUUID, muted: action.isMuted)
        
        guard let callActionSync = callsManager.call(forUUID: action.callUUID) else {
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
        
        callsCoordinator?.didActivateCallAudioSession()
        
        Task { @MainActor in
            callsCoordinator?.configureWebRTCAudioSession()
        }
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        MEGALogDebug("[CallKit] Provider did deactivate audio session")
        
        callsCoordinator?.didDeactivateCallAudioSession()
    }
    
    // MARK: - Private
    @MainActor private func manageActionSuccess(_ action: CXAction, success: Bool) {
        if success {
            action.fulfill()
        } else {
            action.fail()
        }
    }
    
    private func answerCall(forAction action: CXAnswerCallAction) {
        guard let callsCoordinator,
              let callActionSync = callsManager.call(forUUID: action.callUUID)
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
