
@objc final class CallActionManager: NSObject {
    @objc static let shared = CallActionManager()
    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()
    private var callAvailabilityListener: CallAvailabilityListener?
    private var chatOnlineListener: ChatOnlineListener?

    private override init() { super.init() }
    
    @objc func startCall(chatId: UInt64, enableVideo: Bool, enableAudio: Bool, delegate: MEGAChatRequestDelegate) {
        self.chatOnlineListener = ChatOnlineListener(
            chatId: chatId,
            sdk: chatSdk
        ) { [weak self] chatId in
            guard let self = self else { return }
            self.chatOnlineListener = nil
            MEGALogDebug("CallActionManager: state is online now \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") ")
            
            self.chatSdk.startChatCall(chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: delegate)
        }
    }
    
    @objc func answerCall(chatId: UInt64, enableVideo: Bool, enableAudio: Bool, delegate: MEGAChatRequestDelegate) {
        let group = DispatchGroup()
        
        group.enter()
        self.chatOnlineListener = ChatOnlineListener(
            chatId: chatId,
            sdk: chatSdk
        ) { [weak self] chatId in
            guard let self = self else { return }
            self.chatOnlineListener = nil
            MEGALogDebug("CallActionManager: state is online now \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") ")
            group.leave()
        }
        
        group.enter()
        self.callAvailabilityListener = CallAvailabilityListener(
            chatId: chatId,
            sdk: self.chatSdk
        ) { [weak self] chatId, call  in
            guard let self = self else { return }
            self.callAvailabilityListener = nil
            MEGALogDebug("CallActionManager: Call is now available for \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") - \(call)")
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.chatSdk.answerChatCall(chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: delegate)
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
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk!, chatId: UInt64, newState: Int32) {
        if self.chatId == chatId,
           newState == MEGAChatConnection.online.rawValue {
            MEGALogDebug("Create meeting: chat state changed to online now for chat id \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
            removeListener()
            completion?(chatId)
            self.completion = nil
        } else if (self.chatId == chatId) {
            MEGALogDebug("Create meeting: new state is \(newState) for chat id \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
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
    func onChatCallUpdate(_ api: MEGAChatSdk!, call: MEGAChatCall!) {
        if call.chatId == chatId {
            MEGALogDebug("Create meeting: onChatCallUpdate for \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
            if let call = call {
                MEGALogDebug("Create meeting: call object is \(call)")
                removeListener()
                completion?(chatId, call)
                self.completion = nil
            } else {
                MEGALogDebug("Create meeting: no call object found for  \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
            }
        }
    }
}

