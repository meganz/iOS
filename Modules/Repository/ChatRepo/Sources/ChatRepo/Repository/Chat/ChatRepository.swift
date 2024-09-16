@preconcurrency import Combine
import MEGAChatSdk
import MEGADomain
import MEGASDKRepo

public final class ChatRepository: ChatRepositoryProtocol {
    
    public static var newRepo: ChatRepository {
        ChatRepository(chatSDK: .sharedChatSdk)
    }
    
    private let chatSDK: MEGAChatSdk
    
    private let chatStatusUpdateListener: ChatStatusUpdateListener
    private let chatListItemUpdateListener: ChatListItemUpdateListener
    private let chatCallUpdateListener: ChatCallUpdateListener
    private let chatConnectionUpdateListener: ChatConnectionUpdateListener
    private let chatRequestListener: ChatRequestListener
    private let listeners: [any ChatUpdateListenable]
    
    public init(chatSDK: MEGAChatSdk) {
        self.chatSDK = chatSDK
        
        chatStatusUpdateListener = ChatStatusUpdateListener(sdk: chatSDK)
        chatListItemUpdateListener = ChatListItemUpdateListener(sdk: chatSDK)
        chatCallUpdateListener = ChatCallUpdateListener(sdk: chatSDK)
        chatConnectionUpdateListener = ChatConnectionUpdateListener(sdk: chatSDK)
        chatRequestListener = ChatRequestListener(sdk: chatSDK)
        
        listeners = [
            chatStatusUpdateListener,
            chatListItemUpdateListener,
            chatCallUpdateListener,
            chatConnectionUpdateListener,
            chatRequestListener
        ]
        
        Task {
            listeners.forEach { $0.startListening() }
        }
    }
    
    deinit {
        Task { [listeners] in
            listeners.forEach { $0.stopListening() }
        }
    }
    
    public func myUserHandle() -> HandleEntity {
        chatSDK.myUserHandle
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
    
    public func chatConnectionStatus(for chatId: ChatIdEntity) -> ChatConnectionStatus {
        chatSDK.chatConnectionState(chatId).toChatConnectionStatus()
    }
    
    public func chatListItem(forChatId chatId: ChatIdEntity) -> ChatListItemEntity? {
        chatSDK.chatListItem(forChatId: chatId)?.toChatListItemEntity()
    }
    
    public func retryPendingConnections() {
        chatSDK.retryPendingConnections()
    }
    
    public func monitorChatStatusChange() -> AnyPublisher<(HandleEntity, ChatStatusEntity), Never> {
        chatStatusUpdateListener
            .monitor
            .eraseToAnyPublisher()
    }
    
    public func monitorChatListItemUpdate() -> AnyPublisher<[ChatListItemEntity], Never> {
        chatListItemUpdateListener
            .monitor
            .collect(.byTime(DispatchQueue.global(qos: .background), .seconds(5)))
            .eraseToAnyPublisher()
    }
    
    public func existsActiveCall() -> Bool {
        chatSDK.firstActiveCall != nil
    }
    
    public func activeCall() -> CallEntity? {
        chatSDK.firstActiveCall?.toCallEntity()
    }
    
    public func fetchMeetings() -> [ChatListItemEntity]? {
        guard let chatList = chatSDK.chatListItems(by: [.meetingOrNonMeeting, .archivedOrNonArchived], filter: .meeting) else { return nil }
        return (0..<chatList.size).compactMap { chatList.chatListItem(at: $0)?.toChatListItemEntity() }
    }
    
    public func fetchNonMeetings() -> [ChatListItemEntity]? {
        guard let chatList = chatSDK.chatListItems(by: [.meetingOrNonMeeting, .archivedOrNonArchived], filter: []) else { return nil }
        return (0..<chatList.size).compactMap { chatList.chatListItem(at: $0)?.toChatListItemEntity() }
    }
    
    public func isCallInProgress(for chatRoomId: HandleEntity) -> Bool {
        guard let call = chatSDK.chatCall(forChatId: chatRoomId) else {
            return false
        }
        return call.isCallInProgress
    }
    
    public func isCallActive(for chatId: HandleEntity) -> Bool {
        guard let call = chatSDK.chatCall(forChatId: chatId) else {
            return false
        }
        return call.isActiveCall
    }
    
    public func isActiveWaitingRoom(for chatId: HandleEntity) -> Bool {
        chatSDK.chatCall(forChatId: chatId)?.isActiveWaitingRoom == true
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
        chatConnectionUpdateListener
            .monitor
            .filter { $1 == chatId }
            .map(\.0)
            .eraseToAnyPublisher()
    }
    
    public func monitorChatPrivateModeUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatRoomEntity, Never> {
        chatRequestListener
            .monitor
            .filter { $0.chatId == chatId && $1 == .setPrivateMode }
            .map(\.0)
            .eraseToAnyPublisher()
    }
    
    public func chatCall(for chatId: HandleEntity) -> CallEntity? {
        guard let call = chatSDK.chatCall(forChatId: chatId) else {
            return nil
        }
        
        return call.toCallEntity()
    }
}

protocol ChatUpdateListenable: Sendable {
    func startListening()
    func stopListening()
}

private final class ChatStatusUpdateListener: NSObject, MEGAChatDelegate, ChatUpdateListenable {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<(HandleEntity, ChatStatusEntity), Never>()
    
    var monitor: AnyPublisher<(HandleEntity, ChatStatusEntity), Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func startListening() {
        sdk.add(self, queueType: .globalBackground)
    }
    
    func stopListening() {
        sdk.remove(self)
    }
    
    func onChatOnlineStatusUpdate(_ api: MEGAChatSdk, userHandle: UInt64, status onlineStatus: MEGAChatStatus, inProgress: Bool) {
        guard !inProgress else {
            return
        }
        
        source.send((userHandle, onlineStatus.toChatStatusEntity()))
    }
}

private final class ChatListItemUpdateListener: NSObject, MEGAChatDelegate, ChatUpdateListenable {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<ChatListItemEntity, Never>()
    
    var monitor: AnyPublisher<ChatListItemEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func startListening() {
        sdk.add(self, queueType: .globalBackground)
    }
    
    func stopListening() {
        sdk.remove(self)
    }
    
    func onChatListItemUpdate(_ api: MEGAChatSdk, item: MEGAChatListItem) {
        source.send(item.toChatListItemEntity())
    }
}

private final class ChatConnectionUpdateListener: NSObject, MEGAChatDelegate, ChatUpdateListenable {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<(ChatConnectionStatus, ChatIdEntity), Never>()
    
    var monitor: AnyPublisher<(ChatConnectionStatus, ChatIdEntity), Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func startListening() {
        sdk.add(self, queueType: .globalBackground)
    }
    
    func stopListening() {
        sdk.remove(self)
    }
    
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk, chatId: UInt64, newState: Int32) {
        if let chatConnectionState = MEGAChatConnection(rawValue: Int(newState))?.toChatConnectionStatus() {
            source.send((chatConnectionState, chatId))
        }
    }
}

private final class ChatCallUpdateListener: NSObject, MEGAChatCallDelegate, ChatUpdateListenable {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<CallEntity, Never>()
    
    var monitor: AnyPublisher<CallEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func startListening() {
        sdk.add(self)
    }
    
    func stopListening() {
        sdk.remove(self)
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        if call.hasChanged(for: .status) {
            source.send(call.toCallEntity())
        }
    }
}

private final class ChatRequestListener: NSObject, MEGAChatRequestDelegate, ChatUpdateListenable {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<(ChatRoomEntity, MEGAChatRequestType), Never>()
    
    var monitor: AnyPublisher<(ChatRoomEntity, MEGAChatRequestType), Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func startListening() {
        sdk.add(self, queueType: .globalBackground)
    }
    
    func stopListening() {
        sdk.remove(self)
    }
    
    func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        if let chatRoom = sdk.chatRoom(forChatId: request.chatHandle) {
            source.send((chatRoom.toChatRoomEntity(), request.type))
        }
    }
}
