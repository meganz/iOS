import MEGADomain

@objc final class CallActionManager: NSObject {
    @objc static let shared = CallActionManager()
    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()
    private var callAvailabilityListener: CallAvailabilityListener?
    private var chatOnlineListener: ChatOnlineListener?
    private var callInProgressListener: CallInProgressListener?
    var didEnableWebrtcAudioNow: Bool = false
    private var enableRTCAudioExternally = false
    private var startCallRequestDelegate: MEGAChatStartCallRequestDelegate?
    private var answerCallRequestDelegate: MEGAChatAnswerCallRequestDelegate?
    
    private var megaCallManager: MEGACallManager? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let callManager = appDelegate.megaCallManager else {
            return nil
        }
        
        return callManager
    }
    
    private var providerDelegate: MEGAProviderDelegate? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let megaProviderDelegate = appDelegate.megaProviderDelegate else {
            return nil
        }
        
        return megaProviderDelegate
    }

    private override init() { super.init() }

    @objc func startCall(chatId: UInt64, enableVideo: Bool, enableAudio: Bool, delegate: MEGAChatStartCallRequestDelegate) {
        self.chatOnlineListener = ChatOnlineListener(
            chatId: chatId,
            sdk: chatSdk
        ) { [weak self] chatId in
            guard let self = self else { return }
            self.chatOnlineListener = nil
            MEGALogDebug("1: CallActionManager: state is online now \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") ")
            
            self.configureAudioSessionForStartCall(chatId: chatId)
            self.startCallRequestDelegate = MEGAChatStartCallRequestDelegate { error in
                if error.type == .MEGAChatErrorTypeOk {
                    self.notifyStartCallToCallKit(chatId: chatId)
                    MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo).start(chatId: chatId)
                }
                delegate.completion(error)
            }
            guard let startCallRequestDelegate = self.startCallRequestDelegate else { return }
            self.chatSdk.setChatVideoInDevices("Front Camera")
            self.providerDelegate?.isOutgoingCall = self.isOneToOneChatRoom(forChatId: chatId)
            self.chatSdk.startChatCall(chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: startCallRequestDelegate)
        }
    }
    
    func startCallNoRinging(chatId: ChatIdEntity, scheduledId: UInt64, enableVideo: Bool, enableAudio: Bool, delegate: MEGAChatStartCallRequestDelegate) {
        self.chatOnlineListener = ChatOnlineListener(
            chatId: chatId,
            sdk: chatSdk
        ) { [weak self] chatId in
            guard let self else { return }
            self.chatOnlineListener = nil
            MEGALogDebug("1: CallActionManager: state is online now \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") ")
            
            self.configureAudioSessionForStartCall(chatId: chatId)
            self.startCallRequestDelegate = MEGAChatStartCallRequestDelegate { error in
                if error.type == .MEGAChatErrorTypeOk {
                    self.notifyStartCallToCallKit(chatId: chatId)
                    MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo).start(chatId: chatId)
                }
                delegate.completion(error)
            }
            guard let startCallRequestDelegate = self.startCallRequestDelegate else { return }
            self.chatSdk.setChatVideoInDevices("Front Camera")
            
            self.chatSdk.startChatCallNoRinging(chatId, scheduledId: scheduledId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: startCallRequestDelegate)
        }
    }
    
    @objc func answerCall(chatId: UInt64, enableVideo: Bool, enableAudio: Bool, delegate: MEGAChatAnswerCallRequestDelegate) {
        let group = DispatchGroup()
        
        group.enter()
        self.chatOnlineListener = ChatOnlineListener(
            chatId: chatId,
            sdk: chatSdk
        ) { [weak self] chatId in
            guard let self = self else { return }
            self.chatOnlineListener = nil
            MEGALogDebug("2: CallActionManager: state is online now \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") ")
            group.leave()
        }
        
        group.enter()
        self.callAvailabilityListener = CallAvailabilityListener(
            chatId: chatId,
            sdk: self.chatSdk
        ) { [weak self] chatId, call  in
            guard let self = self else { return }
            self.callAvailabilityListener = nil
            MEGALogDebug("3: CallActionManager: Call is now available for \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") - \(call)")
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let providerDelegate = self.providerDelegate,
               providerDelegate.isAudioSessionActive {
                self.configureAudioSessionForStartCall(chatId: chatId)
            } else {
                if self.disableRTCAudio() {
                    self.enableRTCAudioExternally = true
                    self.enableRTCAudioIfRequiredWhenCallInProgress(chatId: chatId)
                }
            }
            self.answerCallRequestDelegate = MEGAChatAnswerCallRequestDelegate { error in
                if error.type == .MEGAChatErrorTypeOk {
                    self.notifyStartCallToCallKit(chatId: chatId)
                }
                delegate.completion(error)
            }
            guard let answerCallRequestDelegate = self.answerCallRequestDelegate else { return }
            self.chatSdk.setChatVideoInDevices("Front Camera")
            self.chatSdk.answerChatCall(chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: answerCallRequestDelegate)
        }
    }
    
    @objc func enableRTCAudioIfRequired() {
        MEGALogDebug("CallActionManager: enableRTCAudioIfRequired started")
        guard enableRTCAudioExternally else {
            return
        }
        
        MEGALogDebug("CallActionManager: enableRTCAudioIfRequired success")
        enableRTCAudioExternally = false
        enableRTCAudio()
    }
    
    @objc func disableRTCAudioSession() {
        MEGALogDebug("CallActionManager: Disable webrtc audio session")
        if disableRTCAudio() {
            RTCAudioSession.sharedInstance().audioSessionDidDeactivate(AVAudioSession.sharedInstance())
        }
    }
    
    private func notifyStartCallToCallKit(chatId: UInt64) {
        guard let call = chatSdk.chatCall(forChatId: chatId), !isCallAlreadyAdded(call.toCallEntity()) else { return }
        
        MEGALogDebug("CallActionManager: Notifiying call to callkit")
        megaCallManager?.start(call)
        megaCallManager?.add(call)
    }
        
    private func configureAudioSessionForStartCall(chatId: UInt64) {
        guard disableRTCAudio() else { return }
        
        guard !isOneToOneChatRoom(forChatId: chatId) else {
            enableRTCAudioExternally = true
            return
        }
        
        enableRTCAudioIfRequiredWhenCallInProgress(chatId: chatId)
    }
    
    @discardableResult
    private func disableRTCAudio() -> Bool {
        guard let providerDelegate, providerDelegate.isAudioSessionActive == false else {
            return false
        }
        
        MEGALogDebug("CallActionManager: Disable webrtc audio")
        RTCAudioSession.sharedInstance().useManualAudio = true
        RTCAudioSession.sharedInstance().isAudioEnabled = false
        return true
    }
    
    private func enableRTCAudio() {
        MEGALogDebug("CallActionManager: Enable webrtc audio session")
        RTCAudioSession.sharedInstance().audioSessionDidActivate(AVAudioSession.sharedInstance())
        RTCAudioSession.sharedInstance().isAudioEnabled = true
        self.didEnableWebrtcAudioNow = true
    }
    
    private func isCallAlreadyAdded(_ call: CallEntity) -> Bool {
        guard let megaCallManager = megaCallManager,
              let uuid = megaCallManager.uuid(forChatId: call.chatId, callId: call.callId) else {
            return false
        }
        
        return megaCallManager.callId(for: uuid) != 0
    }
    
    private func isOneToOneChatRoom(forChatId chatId: UInt64) -> Bool {
        guard let megaChatRoom = chatSdk.chatRoom(forChatId: chatId) else { return false }
        return megaChatRoom.toChatRoomEntity().chatType == .oneToOne
    }
    
    private func enableRTCAudioIfRequiredWhenCallInProgress(chatId: UInt64) {
        self.callInProgressListener = CallInProgressListener(chatId: chatId, sdk: chatSdk) { [weak self] _, _ in
            // There is a race condition that sometimes microphone does not seem to work when on a call.
            // Once the call state changes to inProgress, after one second delay we are checking if the microphone is disabled. Enable it in case it is disabled.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !RTCAudioSession.sharedInstance().isAudioEnabled {
                    self?.enableRTCAudio()
                    MEGALogDebug("CallActionManager: Enabled webrtc audio session (enableRTCAudioIfRequiredWhenCallInProgress)")
                } else {
                    MEGALogDebug("CallActionManager: RTCSession was already enabled")
                }
            }
            self?.callInProgressListener = nil
        }
    }
}

private final class ChatOnlineListener: NSObject {
    private let chatId: UInt64
    typealias Completion = (_ chatId: UInt64) -> Void
    private var completion: Completion?
    private let sdk: MEGAChatSdk

    init(chatId: UInt64,
         sdk: MEGAChatSdk,
         completion: @escaping Completion) {
        self.chatId = chatId
        self.sdk = sdk
        self.completion = completion
        super.init()
        
        if sdk.chatConnectionState(chatId) == .online {
            completion(chatId)
            self.completion = nil
        } else {
            addListener()
        }
    }
    
    private func addListener() {
        sdk.add(self as MEGAChatDelegate)
    }
    
    private func removeListener() {
        sdk.remove(self as MEGAChatDelegate)
    }
}

extension ChatOnlineListener: MEGAChatDelegate {
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk, chatId: UInt64, newState: Int32) {
        if self.chatId == chatId,
           newState == MEGAChatConnection.online.rawValue {
            MEGALogDebug("CallActionManager: chat state changed to online now for chat id \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
            removeListener()
            completion?(chatId)
            self.completion = nil
        } else if self.chatId == chatId {
            MEGALogDebug("CallActionManager: new state is \(newState) for chat id \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
        }
    }
}

private final class CallAvailabilityListener: NSObject {
    private let chatId: UInt64
    typealias Completion = (_ chatId: UInt64, _ call: MEGAChatCall) -> Void
    private var completion: Completion?
    private let sdk: MEGAChatSdk

    init(chatId: UInt64,
         sdk: MEGAChatSdk,
         completion: @escaping Completion) {
        self.chatId = chatId
        self.sdk = sdk
        self.completion = completion
        super.init()
        
        if let call = sdk.chatCall(forChatId: chatId) {
            completion(chatId, call)
            self.completion = nil
        } else {
            addListener()
        }
    }
    
    private func addListener() {
        sdk.add(self as MEGAChatCallDelegate)
    }
    
    private func removeListener() {
        sdk.remove(self as MEGAChatCallDelegate)
    }
}

extension CallAvailabilityListener: MEGAChatCallDelegate {
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        if call.chatId == chatId {
            MEGALogDebug("CallActionManager: onChatCallUpdate for \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
            MEGALogDebug("CallActionManager: call object is \(call)")
            removeListener()
            completion?(chatId, call)
            self.completion = nil
        }
    }
}

private final class CallInProgressListener: NSObject {
    private let chatId: UInt64
    typealias Completion = (_ chatId: UInt64, _ call: MEGAChatCall) -> Void
    private var completion: Completion?
    private let sdk: MEGAChatSdk

    init(chatId: UInt64,
         sdk: MEGAChatSdk,
         completion: @escaping Completion) {
        self.chatId = chatId
        self.sdk = sdk
        self.completion = completion
        super.init()
        addListener()
    }
    
    private func addListener() {
        sdk.add(self as MEGAChatCallDelegate)
    }
    
    private func removeListener() {
        sdk.remove(self as MEGAChatCallDelegate)
    }
}

extension CallInProgressListener: MEGAChatCallDelegate {
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        if call.chatId == chatId {
            MEGALogDebug("CallActionManager: onChatCallUpdate for \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
            if call.status == .inProgress {
                MEGALogDebug("CallActionManager: call object is \(call)")
                removeListener()
                completion?(chatId, call)
                self.completion = nil
            }
        }
    }
}
