import MEGADomain
import Combine

public final class ChatRepository: ChatRepositoryProtocol {
    private let sdk: MEGAChatSdk
    private var chatStatusUpdateListeners = [ChatStatusUpdateListener]()
    private lazy var chatListItemUpdateListener = ChatListItemUpdateListener(sdk: sdk)
    private lazy var chatCallUpdateListener = ChatCallUpdateListener(sdk: sdk)

    public init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
    
    public func chatStatus() -> ChatStatusEntity {
        sdk.onlineStatus().toChatStatusEntity()
    }
    
    public func changeChatStatus(to status: ChatStatusEntity) {
        sdk.setOnlineStatus(status.toMEGASChatStatus())
    }
    
    public func archivedChatListCount() -> UInt {
        sdk.archivedChatListItems?.size ?? 0
    }
    
    public func unreadChatMessagesCount() -> Int {
        sdk.unreadChats
    }
    
    public func monitorChatStatusChange(forUserHandle userHandle: HandleEntity) -> AnyPublisher<ChatStatusEntity, Never> {
        chatStatusUpdateListener(forUserHandle: userHandle)
            .monitor
            .eraseToAnyPublisher()
    }
    
    public func monitorChatListItemUpdate() -> AnyPublisher<ChatListItemEntity, Never> {
        chatListItemUpdateListener
            .monitor
            .eraseToAnyPublisher()
    }
    
    public func existsActiveCall() -> Bool {
        sdk.firstActiveCall != nil
    }
    
    public func activeCall() -> CallEntity? {
        sdk.firstActiveCall?.toCallEntity()
    }
    
    public func chatsList(ofType type: ChatTypeEntity) -> [ChatListItemEntity]? {
        guard let chatList = sdk.chatListItems(by: type.toMEGAChatType()) else { return nil }
        var chatListItems = [ChatListItemEntity]()
        for i in 0 ..< chatList.size {
            chatListItems.append(chatList.chatListItem(at: i).toChatListItemEntity())
        }
        return chatListItems
    }
    
    public func isCallInProgress(for chatRoomId: HandleEntity) -> Bool {
        guard let call = sdk.chatCall(forChatId: chatRoomId) else {
            return false
        }
        return call.isCallInProgress
    }
    
    public func myFullName() -> String? {
        sdk.myFullname
    }
    
    public func monitorChatCallStatusUpdate() -> AnyPublisher<CallEntity, Never> {
        chatCallUpdateListener
            .monitor
            .eraseToAnyPublisher()
    }
    
    // - MARK: Private
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

fileprivate final class ChatListItemUpdateListener: NSObject, MEGAChatDelegate {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<ChatListItemEntity, Never>()

    var monitor: AnyPublisher<ChatListItemEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onChatListItemUpdate(_ api: MEGAChatSdk!, item: MEGAChatListItem!) {
        source.send(item.toChatListItemEntity())
    }
}

fileprivate final class ChatCallUpdateListener: NSObject, MEGAChatCallDelegate {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<CallEntity, Never>()

    var monitor: AnyPublisher<CallEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk!, call: MEGAChatCall!) {
        if call.hasChanged(for: .status) {
            source.send(call.toCallEntity())
        }
    }
}

