import MEGADomain
import Combine

public final class MockChatUseCase: ChatUseCaseProtocol {
    public var userHandle: HandleEntity
    public var guestAccount: Bool
    public var fullName: String?
    public var status: ChatStatusEntity
    public var isCallActive: Bool
    public var isCallInProgress: Bool
    public var activeCallEntity: CallEntity?
    public var statusChangePublisher: PassthroughSubject<ChatStatusEntity, Never>
    public var chatListItemUpdatePublisher: PassthroughSubject<[ChatListItemEntity], Never>
    public var chatCallStatusUpdatePublisher: PassthroughSubject<CallEntity, Never>
    public var chatConnectionStatusUpdatePublisher: PassthroughSubject<ChatConnectionStatus , Never>
    public var chatPrivateModeUpdatePublisher: PassthroughSubject<ChatRoomEntity , Never>
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
        isCallActive: Bool = false,
        isCallInProgress: Bool = false,
        statusChangePublisher: PassthroughSubject<ChatStatusEntity, Never> = PassthroughSubject<ChatStatusEntity, Never>(),
        chatListItemUpdatePublisher: PassthroughSubject<[ChatListItemEntity], Never> =  PassthroughSubject<[ChatListItemEntity], Never>(),
        chatCallStatusUpdatePublisher: PassthroughSubject<CallEntity, Never> = PassthroughSubject<CallEntity, Never>(),
        chatConnectionStatusUpdatePublisher: PassthroughSubject<ChatConnectionStatus, Never> = PassthroughSubject<ChatConnectionStatus, Never>(),
        chatPrivateModeUpdatePublisher: PassthroughSubject<ChatRoomEntity , Never> = PassthroughSubject<ChatRoomEntity , Never>(),
        items: [ChatListItemEntity]? = []
    ) {
        self.userHandle = myUserHandle
        self.guestAccount = isGuestAccount
        self.fullName = fullName
        self.status = status
        self.isCallActive = isCallActive
        self.isCallInProgress = isCallInProgress
        self.statusChangePublisher = statusChangePublisher
        self.chatListItemUpdatePublisher = chatListItemUpdatePublisher
        self.chatCallStatusUpdatePublisher = chatCallStatusUpdatePublisher
        self.chatConnectionStatusUpdatePublisher = chatConnectionStatusUpdatePublisher
        self.chatPrivateModeUpdatePublisher = chatPrivateModeUpdatePublisher
        self.items = items
    }
    
    public func myUserHandle() -> MEGADomain.HandleEntity {
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
    
    public func monitorChatStatusChange(forUserHandle userHandle: HandleEntity) -> AnyPublisher<ChatStatusEntity, Never> {
        statusChangePublisher.eraseToAnyPublisher()
    }
    
    public func monitorChatListItemUpdate() -> AnyPublisher<[ChatListItemEntity], Never> {
        chatListItemUpdatePublisher.eraseToAnyPublisher()
    }
    
    public func existsActiveCall() -> Bool {
        isCallActive
    }
    
    public func activeCall() -> MEGADomain.CallEntity? {
        activeCallEntity
    }
    
    public func chatsList(ofType type: ChatTypeEntity) -> [ChatListItemEntity]? {
        items
    }
    
    public func isCallInProgress(for chatRoomId: MEGADomain.HandleEntity) -> Bool {
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
    
    public func monitorChatCallStatusUpdate() -> AnyPublisher<MEGADomain.CallEntity, Never> {
        chatCallStatusUpdatePublisher.eraseToAnyPublisher()
    }
    
    public func monitorChatConnectionStatusUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatConnectionStatus, Never> {
        chatConnectionStatusUpdatePublisher.eraseToAnyPublisher()
    }
    
    public func chatConnectionStatus() -> ChatConnectionStatus {
        currentChatConnectionStatus
    }
    
    public func chatListItem(forChatId chatId: MEGADomain.ChatIdEntity) -> ChatListItemEntity? {
        items?.first
    }
    
    public func retryPendingConnections() {
        retryPendingConnections_calledTimes += 1
    }
    
    public func monitorChatPrivateModeUpdate(forChatId chatId: MEGADomain.HandleEntity) -> AnyPublisher<MEGADomain.ChatRoomEntity, Never> {
        chatPrivateModeUpdatePublisher.eraseToAnyPublisher()
    }
    
    public func scheduledMeetings() -> [ScheduledMeetingEntity] {
        scheduledMeetingList
    }
}
