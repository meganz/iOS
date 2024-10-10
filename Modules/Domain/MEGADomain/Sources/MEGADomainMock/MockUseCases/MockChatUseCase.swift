@preconcurrency import Combine
import MEGADomain

public final class MockChatUseCase: ChatUseCaseProtocol, @unchecked Sendable {
    public var userHandle: HandleEntity
    public var guestAccount: Bool
    public var fullName: String?
    public var status: ChatStatusEntity
    public var isExistingActiveCall: Bool
    public var isCallActive: Bool
    public var isCallInProgress: Bool
    public var isActiveWaitingRoom: Bool
    public var activeCallEntity: CallEntity?
    public var statusChangePublisher: PassthroughSubject<(HandleEntity, ChatStatusEntity), Never>
    public var chatListItemUpdatePublisher: PassthroughSubject<[ChatListItemEntity], Never>
    public var chatCallStatusUpdatePublisher: PassthroughSubject<CallEntity, Never>
    public var chatConnectionStatusUpdatePublisher: PassthroughSubject<ChatConnectionStatus, Never>
    public var chatPrivateModeUpdatePublisher: PassthroughSubject<ChatRoomEntity, Never>
    public var items: [ChatListItemEntity]?
    public var archivedChatsCount: UInt = 0
    public var totalUnreadChats = 0
    public var currentChatConnectionStatus = ChatConnectionStatus.invalid
    public var retryPendingConnections_calledTimes = 0
    public var scheduledMeetingList = [ScheduledMeetingEntity]()
    
    public init(
        myUserHandle: HandleEntity = .invalid,
        isGuestAccount: Bool = false,
        fullName: String? = nil,
        status: ChatStatusEntity = .offline,
        isExistingActiveCall: Bool = false,
        isCallActive: Bool = false,
        isCallInProgress: Bool = false,
        isActiveWaitingRoom: Bool = false,
        activeCallEntity: CallEntity? = nil,
        statusChangePublisher: PassthroughSubject<(HandleEntity, ChatStatusEntity), Never> = .init(),
        chatListItemUpdatePublisher: PassthroughSubject<[ChatListItemEntity], Never> =  .init(),
        chatCallStatusUpdatePublisher: PassthroughSubject<CallEntity, Never> = .init(),
        chatConnectionStatusUpdatePublisher: PassthroughSubject<ChatConnectionStatus, Never> = .init(),
        chatPrivateModeUpdatePublisher: PassthroughSubject<ChatRoomEntity, Never> = .init(),
        items: [ChatListItemEntity]? = [],
        currentChatConnectionStatus: ChatConnectionStatus = .invalid
    ) {
        self.userHandle = myUserHandle
        self.guestAccount = isGuestAccount
        self.fullName = fullName
        self.status = status
        self.isExistingActiveCall = isExistingActiveCall
        self.isCallActive = isCallActive
        self.isCallInProgress = isCallInProgress
        self.isActiveWaitingRoom = isActiveWaitingRoom
        self.activeCallEntity = activeCallEntity
        self.statusChangePublisher = statusChangePublisher
        self.chatListItemUpdatePublisher = chatListItemUpdatePublisher
        self.chatCallStatusUpdatePublisher = chatCallStatusUpdatePublisher
        self.chatConnectionStatusUpdatePublisher = chatConnectionStatusUpdatePublisher
        self.chatPrivateModeUpdatePublisher = chatPrivateModeUpdatePublisher
        self.items = items
        self.currentChatConnectionStatus = currentChatConnectionStatus
    }
    
    public func myUserHandle() -> HandleEntity {
        userHandle
    }
    
    public func isGuestAccount() -> Bool {
        guestAccount
    }
    
    public func chatStatus() -> ChatStatusEntity {
        status
    }
    
    public func changeChatStatus(to status: ChatStatusEntity) {
        self.status = status
    }
    
    public func monitorChatStatusChange() -> AnyPublisher<(HandleEntity, ChatStatusEntity), Never> {
        statusChangePublisher.eraseToAnyPublisher()
    }
    
    public func monitorChatListItemUpdate() -> AnyPublisher<[ChatListItemEntity], Never> {
        chatListItemUpdatePublisher.eraseToAnyPublisher()
    }
    
    public func existsActiveCall() -> Bool {
        isExistingActiveCall
    }
    
    public func activeCall() -> CallEntity? {
        activeCallEntity
    }
    
    public func fetchNonMeetings() -> [ChatListItemEntity]? {
        items
    }
    
    public func fetchMeetings() -> [ChatListItemEntity]? {
        items
    }
    
    public func isCallInProgress(for chatRoomId: HandleEntity) -> Bool {
        isCallInProgress
    }
    
    public func myFullName() -> String? {
        fullName
    }
    
    public func archivedChatListCount() -> UInt {
        archivedChatsCount
    }
    
    public func unreadChatMessagesCount() -> Int {
        totalUnreadChats
    }
    
    public func monitorChatCallStatusUpdate() -> AnyPublisher<CallEntity, Never> {
        chatCallStatusUpdatePublisher.eraseToAnyPublisher()
    }
    
    public func monitorChatConnectionStatusUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatConnectionStatus, Never> {
        chatConnectionStatusUpdatePublisher.eraseToAnyPublisher()
    }
    
    public func chatConnectionStatus() -> ChatConnectionStatus {
        currentChatConnectionStatus
    }
    
    public func chatListItem(forChatId chatId: ChatIdEntity) -> ChatListItemEntity? {
        items?.first
    }
    
    public func retryPendingConnections() {
        retryPendingConnections_calledTimes += 1
    }
    
    public func monitorChatPrivateModeUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatRoomEntity, Never> {
        chatPrivateModeUpdatePublisher.eraseToAnyPublisher()
    }
    
    public func scheduledMeetings() -> [ScheduledMeetingEntity] {
        scheduledMeetingList
    }
    
    public func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [ScheduledMeetingEntity] {
        scheduledMeetingList
    }
    
    public func chatCall(for chatId: HandleEntity) async -> CallEntity? {
        activeCallEntity
    }
    
    public func chatConnectionStatus(for chatId: ChatIdEntity) async -> ChatConnectionStatus {
        currentChatConnectionStatus
    }
    
    public func isCallActive(for chatId: MEGADomain.HandleEntity) -> Bool {
        isCallActive
    }
    
    public func isActiveWaitingRoom(for chatId: MEGADomain.HandleEntity) -> Bool {
        isActiveWaitingRoom
    }
}
