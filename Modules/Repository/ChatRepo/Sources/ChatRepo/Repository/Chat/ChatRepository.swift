@preconcurrency import Combine
import MEGAChatSdk
import MEGADomain
import MEGASDKRepo

public final class ChatRepository: ChatRepositoryProtocol, Sendable {
    
    public static var newRepo: ChatRepository {
        ChatRepository(chatSDK: .sharedChatSdk)
    }
    
    private let chatSDK: MEGAChatSdk
    private let chatStatusUpdateListener: ChatStatusUpdateListener
    private let chatListItemUpdateListener: ChatListItemUpdateListener
    private let chatCallUpdateListener: ChatCallUpdateListener
    private let chatConnectionUpdateListener: ChatConnectionUpdateListener
    private let chatRequestListener: ChatRequestListener
    
    public init(chatSDK: MEGAChatSdk) {
        self.chatSDK = chatSDK
        chatStatusUpdateListener = ChatStatusUpdateListener(sdk: chatSDK)
        chatStatusUpdateListener.addListenerAsync()
        
        chatListItemUpdateListener = ChatListItemUpdateListener(sdk: chatSDK)
        chatListItemUpdateListener.addListenerAsync()
        
        chatCallUpdateListener = ChatCallUpdateListener(sdk: chatSDK)
        chatCallUpdateListener.addListenerAsync()
        
        chatConnectionUpdateListener = ChatConnectionUpdateListener(sdk: chatSDK)
        chatConnectionUpdateListener.addListenerAsync()

        chatRequestListener = ChatRequestListener(sdk: chatSDK)
        chatRequestListener.addListenerAsync()
    }
    
    deinit {
        chatStatusUpdateListener.removeListenerAsync()
        chatListItemUpdateListener.removeListenerAsync()
        chatCallUpdateListener.removeListenerAsync()
        chatConnectionUpdateListener.removeListenerAsync()
        chatRequestListener.removeListenerAsync()
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
    
    public func monitorChatListItemSingleUpdate() -> AnyPublisher<ChatListItemEntity, Never> {
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
            .filter { $0.changeType == .status }
            .eraseToAnyPublisher()
    }
    
    public func monitorChatCallUpdate() -> AnyPublisher<CallEntity, Never> {
        chatCallUpdateListener.monitor.eraseToAnyPublisher()
    }
    
    public func monitorChatCallUpdate(for callId: HandleEntity, changeTypes: Set<CallEntity.ChangeType>) -> AnyPublisher<CallEntity, Never> {
        chatCallUpdateListener
            .monitor
            .filter { callEntity in
                guard callEntity.callId == callId else { return false }
                guard let changeType = callEntity.changeType, changeTypes.contains(changeType) else { return false }
                return false
            }.eraseToAnyPublisher()
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
    
    public func listenForChatOnline(_ chatId: HandleEntity) async {
        var subscription: AnyCancellable?
        
        await withCheckedContinuation { continuation in
            
            if chatSDK.chatConnectionState(chatId) == .online {
                continuation.resume()
                return
            }
            
            subscription = monitorChatConnectionStatusUpdate(
                forChatId: chatId
            ).first(
                where: { $0 == .online }
            ).sink(receiveValue: { _ in
                subscription?.cancel()
                continuation.resume()
            })
        }
    }
    
    public func listenForCallAvailability(_ chatId: HandleEntity) async {
        var subscription: AnyCancellable?
        
        return await withCheckedContinuation { continuation in
            if chatSDK.chatCall(forChatId: chatId) != nil {
                continuation.resume()
                return
            }
            
            subscription = chatCallUpdateListener
                .monitor
                .filter { $0.callId == chatId }
                .sink(receiveValue: { _ in
                    subscription?.cancel()
                    continuation.resume()
                })
        }
    }
}

private protocol ChatListener: Sendable {
    var sdk: MEGAChatSdk { get }
}

private extension ChatListener where Self: MEGAChatDelegate {
    func addListenerAsync() {
        Task {
            sdk.add(self, queueType: .globalBackground)
        }
    }
    
    func removeListenerAsync() {
        sdk.removeMEGAChatDelegateAsync(self)
    }
}

private final class ChatStatusUpdateListener: NSObject, ChatListener, MEGAChatDelegate {
    let sdk: MEGAChatSdk
    private let source = PassthroughSubject<(HandleEntity, ChatStatusEntity), Never>()
    var monitor: AnyPublisher<(HandleEntity, ChatStatusEntity), Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
    
    func onChatOnlineStatusUpdate(_ api: MEGAChatSdk, userHandle: UInt64, status onlineStatus: MEGAChatStatus, inProgress: Bool) {
        guard !inProgress else {
            return
        }
        
        source.send((userHandle, onlineStatus.toChatStatusEntity()))
    }
}

private final class ChatListItemUpdateListener: NSObject, ChatListener, MEGAChatDelegate {
    let sdk: MEGAChatSdk
    private let source = PassthroughSubject<ChatListItemEntity, Never>()
    var monitor: AnyPublisher<ChatListItemEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
    
    func onChatListItemUpdate(_ api: MEGAChatSdk, item: MEGAChatListItem) {
        source.send(item.toChatListItemEntity())
    }
}

private final class ChatConnectionUpdateListener: NSObject, ChatListener, MEGAChatDelegate {
    let sdk: MEGAChatSdk
    private let source = PassthroughSubject<(ChatConnectionStatus, ChatIdEntity), Never>()
    var monitor: AnyPublisher<(ChatConnectionStatus, ChatIdEntity), Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
    
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk, chatId: UInt64, newState: Int32) {
        if let chatConnectionState = MEGAChatConnection(rawValue: Int(newState))?.toChatConnectionStatus() {
            source.send((chatConnectionState, chatId))
        }
    }
}

private final class ChatCallUpdateListener: NSObject, MEGAChatCallDelegate, Sendable {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<CallEntity, Never>()
    
    var monitor: AnyPublisher<CallEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func addListenerAsync() {
        Task {
            sdk.add(self)
        }
    }
    
    func removeListenerAsync() {
        sdk.removeMEGACallDelegateAsync(self)
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        source.send(call.toCallEntity())
    }
}

private final class ChatRequestListener: NSObject, MEGAChatRequestDelegate, Sendable {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<(ChatRoomEntity, MEGAChatRequestType), Never>()
    
    var monitor: AnyPublisher<(ChatRoomEntity, MEGAChatRequestType), Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func addListenerAsync() {
        Task {
            sdk.add(self, queueType: .globalBackground)
        }
    }
    
    func removeListenerAsync() {
        sdk.removeMEGAChatRequestDelegateAsync(self)
    }
    
    func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        if let chatRoom = sdk.chatRoom(forChatId: request.chatHandle) {
            source.send((chatRoom.toChatRoomEntity(), request.type))
        }
    }
}
