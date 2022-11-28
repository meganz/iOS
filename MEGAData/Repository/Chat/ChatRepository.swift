import MEGADomain
import Combine

public final class ChatRepository: ChatRepositoryProtocol {
    private let sdk: MEGASdk
    private let chatSDK: MEGAChatSdk
    private var chatStatusUpdateListeners = [ChatStatusUpdateListener]()
    private lazy var chatListItemUpdateListener = ChatListItemUpdateListener(sdk: chatSDK)
    private lazy var chatCallUpdateListener = ChatCallUpdateListener(sdk: chatSDK)
    private var chatConnectionUpdateListener: ChatConnectionUpdateListener?
    private var chatPrivateModeUpdateListener: ChatRequestListener?

    public init(sdk: MEGASdk, chatSDK: MEGAChatSdk) {
        self.sdk = sdk
        self.chatSDK = chatSDK
    }
    
    public func chatStatus() -> ChatStatusEntity {
        chatSDK.onlineStatus().toChatStatusEntity()
    }
    
    public func changeChatStatus(to status: ChatStatusEntity) {
        chatSDK.setOnlineStatus(status.toMEGASChatStatus())
    }
    
    public func archivedChatListCount() -> UInt {
        chatSDK.archivedChatListItems?.size ?? 0
    }
    
    public func unreadChatMessagesCount() -> Int {
        chatSDK.unreadChats
    }
    
    public func chatConnectionStatus() -> ChatConnectionStatus {
        MEGAChatConnection(rawValue: chatSDK.initState().rawValue)?.toChatConnectionStatus() ?? .invalid
    }
    
    public func retryPendingConnections() {
        sdk.retryPendingConnections()
        chatSDK.retryPendingConnections()
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
        chatSDK.firstActiveCall != nil
    }
    
    public func activeCall() -> CallEntity? {
        chatSDK.firstActiveCall?.toCallEntity()
    }
    
    public func chatsList(ofType type: ChatTypeEntity) -> [ChatListItemEntity]? {
        guard let chatList = chatSDK.chatListItems(by: type.toMEGAChatType()) else { return nil }
        var chatListItems = [ChatListItemEntity]()
        for i in 0 ..< chatList.size {
            chatListItems.append(chatList.chatListItem(at: i).toChatListItemEntity())
        }
        return chatListItems
    }
    
    public func isCallInProgress(for chatRoomId: HandleEntity) -> Bool {
        guard let call = chatSDK.chatCall(forChatId: chatRoomId) else {
            return false
        }
        return call.isCallInProgress
    }
    
    public func myFullName() -> String? {
        chatSDK.myFullname
    }
    
    public func monitorChatCallStatusUpdate() -> AnyPublisher<CallEntity, Never> {
        chatCallUpdateListener
            .monitor
            .eraseToAnyPublisher()
    }
    
    public func monitorChatConnectionStatusUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatConnectionStatus, Never> {
        let chatConnectionUpdateListener = ChatConnectionUpdateListener(sdk: chatSDK, chatId: chatId)
        self.chatConnectionUpdateListener = chatConnectionUpdateListener
        return chatConnectionUpdateListener
            .monitor
            .eraseToAnyPublisher()
    }
    
    public func monitorChatPrivateModeUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatRoomEntity, Never> {
        let chatPrivateModeUpdateListener = ChatRequestListener(sdk: chatSDK, chatId: chatId, changeType: .setPrivateMode)
        self.chatPrivateModeUpdateListener = chatPrivateModeUpdateListener
        return chatPrivateModeUpdateListener
            .monitor
            .eraseToAnyPublisher()
    }
    
    // - MARK: Private
    private func chatStatusUpdateListener(forUserHandle userHandle: HandleEntity) -> ChatStatusUpdateListener {
        guard let chatStatusUpdateListener = chatStatusUpdateListeners.filter({ $0.user == userHandle}).first else {
            let chatStatusUpdateListener = ChatStatusUpdateListener(sdk: chatSDK, userHandle: userHandle)
            chatStatusUpdateListeners.append(chatStatusUpdateListener)
            return chatStatusUpdateListener
        }
        
        return chatStatusUpdateListener
    }
}

fileprivate class ChatListener: NSObject, MEGAChatDelegate {
    private let sdk: MEGAChatSdk
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self, queueType: .globalBackground)
    }
    
    deinit {
        sdk.remove(self)
    }
}

fileprivate final class ChatStatusUpdateListener: ChatListener {
    let user: HandleEntity

    private let source = PassthroughSubject<ChatStatusEntity, Never>()

    var monitor: AnyPublisher<ChatStatusEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk, userHandle: HandleEntity) {
        self.user = userHandle
        super.init(sdk: sdk)
    }
    
    func onChatOnlineStatusUpdate(_ api: MEGAChatSdk!, userHandle: UInt64, status onlineStatus: MEGAChatStatus, inProgress: Bool) {
        guard !inProgress, userHandle == user else {
            return
        }
        
        source.send(onlineStatus.toChatStatusEntity())
    }
}

fileprivate final class ChatListItemUpdateListener: ChatListener {
    private let source = PassthroughSubject<ChatListItemEntity, Never>()

    var monitor: AnyPublisher<ChatListItemEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    func onChatListItemUpdate(_ api: MEGAChatSdk!, item: MEGAChatListItem!) {
        source.send(item.toChatListItemEntity())
    }
}

fileprivate final class ChatConnectionUpdateListener: ChatListener {
    private let chatId: ChatId
    private let source = PassthroughSubject<ChatConnectionStatus, Never>()

    var monitor: AnyPublisher<ChatConnectionStatus, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk, chatId: HandleEntity) {
        self.chatId = chatId
        super.init(sdk: sdk)
    }
    
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk!, chatId: UInt64, newState: Int32) {
        if chatId == self.chatId,
           let chatConnectionState = MEGAChatConnection(rawValue: Int(newState))?.toChatConnectionStatus() {
            source.send(chatConnectionState)
        }
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

fileprivate final class ChatRequestListener: NSObject, MEGAChatRequestDelegate {
    private let sdk: MEGAChatSdk
    private let changeType: MEGAChatRequestType
    let chatId: HandleEntity

    private let source = PassthroughSubject<ChatRoomEntity, Never>()

    var monitor: AnyPublisher<ChatRoomEntity, Never> {
        source.eraseToAnyPublisher()
    }

    init(sdk: MEGAChatSdk, chatId: HandleEntity, changeType: MEGAChatRequestType) {
        self.sdk = sdk
        self.changeType = changeType
        self.chatId = chatId
        super.init()
        sdk.add(self)
    }

    deinit {
        sdk.remove(self)
    }

    func onChatRequestFinish(_ api: MEGAChatSdk!, request: MEGAChatRequest!, error: MEGAChatError!) {
        if request.type == changeType,
           chatId == request.chatHandle,
           let chatRoom = sdk.chatRoom(forChatId: chatId) {
            source.send(chatRoom.toChatRoomEntity())
        }
    }
}
