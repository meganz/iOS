import ChatRepo
import MEGADomain

@objc final class CallActionManager: NSObject {
    @objc static let shared = CallActionManager()
    private let chatSdk = MEGAChatSdk.shared
    private var callAvailabilityListener: CallAvailabilityListener?
    private var chatOnlineListener: ChatOnlineListener?
    private var callInProgressListener: CallInProgressListener?
    var didEnableWebrtcAudioNow: Bool = false
    private var enableRTCAudioExternally = false
    private var startCallRequestDelegate: MEGAChatStartCallRequestDelegate?
    private var answerCallRequestDelegate: MEGAChatAnswerCallRequestDelegate?
    private var answerCallChatRequestDelegate: ChatRequestDelegate?
    
    private override init() { super.init() }

    @objc func startCall(chatId: UInt64, enableVideo: Bool, enableAudio: Bool, notRinging: Bool, delegate: MEGAChatStartCallRequestDelegate) {
        self.chatOnlineListener = ChatOnlineListener(
            chatId: chatId,
            sdk: chatSdk
        ) { [weak self] chatId in
            guard let self else { return }
            self.chatOnlineListener = nil
            MEGALogDebug("1: CallActionManager: state is online now \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") ")
            
            self.startCallRequestDelegate = MEGAChatStartCallRequestDelegate { error in
                if error.type == .MEGAChatErrorTypeOk {
                    MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo).start(chatId: chatId)
                }
                delegate.completion(error)
            }
            guard let startCallRequestDelegate = self.startCallRequestDelegate else { return }
            self.chatSdk.setChatVideoInDevices("Front Camera")
            self.chatSdk.startCall(inChat: chatId, enableVideo: enableVideo, enableAudio: enableAudio, notRinging: notRinging, delegate: startCallRequestDelegate)
        }
    }
    
    @MainActor
    func startCall(chatId: ChatIdEntity, enableVideo: Bool, enableAudio: Bool, notRinging: Bool) async throws -> CallEntity {
        try await withCheckedThrowingContinuation { continuation in
            self.chatOnlineListener = ChatOnlineListener(
                chatId: chatId,
                sdk: chatSdk
            ) { [weak self] chatId in
                guard let self else { return }
                chatOnlineListener = nil
                let delegate = ChatRequestDelegate { [weak self] completion in
                    switch completion {
                    case .success:
                        guard let self, let call = chatSdk.chatCall(forChatId: chatId) else {
                            continuation.resume(with: .failure(CallErrorEntity.generic))
                            return
                        }
                        MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo).start(chatId: chatId)
                        continuation.resume(with: .success(call.toCallEntity()))
                    case .failure(let error):
                        switch error.type {
                        case .MEGAChatErrorTooMany:
                            continuation.resume(with: .failure(CallErrorEntity.tooManyParticipants))
                        default:
                            continuation.resume(with: .failure(CallErrorEntity.generic))
                        }
                    }
                }
                chatSdk.setChatVideoInDevices("Front Camera")
                chatSdk.startCall(inChat: chatId, enableVideo: enableVideo, enableAudio: enableAudio, notRinging: notRinging, delegate: delegate)
            }
        }
    }
    
    @objc func answerCall(chatId: UInt64, enableVideo: Bool, enableAudio: Bool, delegate: MEGAChatAnswerCallRequestDelegate) {
        let group = DispatchGroup()
        
        group.enter()
        self.chatOnlineListener = ChatOnlineListener(
            chatId: chatId,
            sdk: chatSdk
        ) { [weak self] chatId in
            guard let self else { return }
            self.chatOnlineListener = nil
            MEGALogDebug("2: CallActionManager: state is online now \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") ")
            group.leave()
        }
        
        group.enter()
        self.callAvailabilityListener = CallAvailabilityListener(
            chatId: chatId,
            sdk: self.chatSdk
        ) { [weak self] chatId, call  in
            guard let self else { return }
            self.callAvailabilityListener = nil
            MEGALogDebug("3: CallActionManager: Call is now available for \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") - \(call)")
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.answerCallRequestDelegate = MEGAChatAnswerCallRequestDelegate { error in
                delegate.completion(error)
            }
            guard let answerCallRequestDelegate = self.answerCallRequestDelegate else { return }
            self.chatSdk.setChatVideoInDevices("Front Camera")
            self.chatSdk.answerChatCall(chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: answerCallRequestDelegate)
        }
    }
    
    func answerCall(chatId: UInt64, enableVideo: Bool, enableAudio: Bool, completion: @escaping MEGAChatRequestCompletion) {
        let group = DispatchGroup()
        
        group.enter()
        chatOnlineListener = ChatOnlineListener(
            chatId: chatId,
            sdk: chatSdk
        ) { [weak self] chatId in
            guard let self else { return }
            chatOnlineListener = nil
            MEGALogDebug("2: CallActionManager: state is online now \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") ")
            group.leave()
        }
        
        group.enter()
        callAvailabilityListener = CallAvailabilityListener(
            chatId: chatId,
            sdk: self.chatSdk
        ) { [weak self] chatId, call  in
            guard let self else { return }
            callAvailabilityListener = nil
            MEGALogDebug("3: CallActionManager: Call is now available for \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1") - \(call)")
            group.leave()
        }
        
        group.notify(queue: .main) { [self] in
            answerCallChatRequestDelegate = ChatRequestDelegate { requestCompletion in
                switch requestCompletion {
                case .success(let request):
                    completion(.success(request))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            guard let answerCallChatRequestDelegate else { return }
            chatSdk.setChatVideoInDevices("Front Camera")
            chatSdk.answerChatCall(chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: answerCallChatRequestDelegate)
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
        sdk.add(self as (any MEGAChatDelegate))
    }
    
    private func removeListener() {
        sdk.remove(self as (any MEGAChatDelegate))
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
        sdk.add(self as (any MEGAChatCallDelegate))
    }
    
    private func removeListener() {
        sdk.remove(self as (any MEGAChatCallDelegate))
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
        sdk.add(self as (any MEGAChatCallDelegate))
    }
    
    private func removeListener() {
        sdk.remove(self as (any MEGAChatCallDelegate))
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
