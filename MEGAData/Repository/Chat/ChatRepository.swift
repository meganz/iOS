import MEGADomain
import Combine

public final class ChatRepository: ChatRepositoryProtocol {
    private let sdk: MEGAChatSdk

    private var chatStatusUpdateListeners = [ChatStatusUpdateListener]()

    public init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
    
    public func chatStatus() -> ChatStatusEntity {
        sdk.onlineStatus().toChatStatusEntity()
    }
    
    public func changeChatStatus(to status: ChatStatusEntity) {
        sdk.setOnlineStatus(status.toMEGASChatStatus())
    }
    
    public func monitorSelfChatStatusChange() -> AnyPublisher<ChatStatusEntity, Never> {
        chatStatusUpdateListener(forUserHandle: sdk.myUserHandle)
            .monitor
            .eraseToAnyPublisher()
    }
    
    private func chatStatusUpdateListener(forUserHandle userHandle: HandleEntity) -> ChatStatusUpdateListener {
        guard let chatStatusUpdateListener = chatStatusUpdateListeners.filter({ $0.user == userHandle}).first else {
            let chatStatusUpdateListener = ChatStatusUpdateListener(sdk: sdk, userHandle: userHandle)
            chatStatusUpdateListeners.append(chatStatusUpdateListener)
            return chatStatusUpdateListener
        }
        
        return chatStatusUpdateListener
    }
}

fileprivate final class ChatStatusUpdateListener: NSObject, MEGAChatDelegate {
    private let sdk: MEGAChatSdk
    let user: HandleEntity

    private let source = PassthroughSubject<ChatStatusEntity, Never>()

    var monitor: AnyPublisher<ChatStatusEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk, userHandle: HandleEntity) {
        self.sdk = sdk
        self.user = userHandle
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onChatOnlineStatusUpdate(_ api: MEGAChatSdk!, userHandle: UInt64, status onlineStatus: MEGAChatStatus, inProgress: Bool) {
        guard !inProgress, userHandle == user else {
            return
        }
        
        source.send(onlineStatus.toChatStatusEntity())
    }
}
