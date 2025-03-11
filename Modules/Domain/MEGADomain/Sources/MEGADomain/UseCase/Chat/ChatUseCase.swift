import Combine

// MARK: - Use case protocol -
public protocol ChatUseCaseProtocol: Sendable {
    func myUserHandle() -> HandleEntity
    func monitorChatStatusChange() -> AnyPublisher<(HandleEntity, ChatStatusEntity), Never>
    func monitorChatListItemUpdate() -> AnyPublisher<[ChatListItemEntity], Never>
    func existsActiveCall() -> Bool
    func activeCall() -> CallEntity?
    func fetchNonMeetings() -> [ChatListItemEntity]?
    func fetchMeetings() -> [ChatListItemEntity]?
    func fetchNoteToSelfChat() -> ChatRoomEntity?
    func createNoteToSelfChat() async throws -> ChatRoomEntity
    func isCallInProgress(for chatRoomId: HandleEntity) -> Bool
    func myFullName() -> String?
    func archivedChatListCount() -> UInt
    func unreadChatMessagesCount() -> Int
    func chatConnectionStatus() -> ChatConnectionStatus
    func chatConnectionStatus(for chatId: ChatIdEntity) async -> ChatConnectionStatus
    func chatListItem(forChatId chatId: ChatIdEntity) -> ChatListItemEntity?
    func retryPendingConnections()
    func monitorChatCallStatusUpdate() -> AnyPublisher<CallEntity, Never>
    func monitorChatConnectionStatusUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatConnectionStatus, Never>
    func monitorChatPrivateModeUpdate(forChatId chatId: ChatIdEntity) -> AnyPublisher<ChatRoomEntity, Never>
    func chatCall(for chatId: HandleEntity) async -> CallEntity?
    func isCallActive(for chatId: HandleEntity) -> Bool
    func isActiveWaitingRoom(for chatId: HandleEntity) -> Bool
}

// MARK: - Use case implementation -
public struct ChatUseCase<T: ChatRepositoryProtocol>: ChatUseCaseProtocol {
    private var chatRepo: T
    
    public init(chatRepo: T) {
        self.chatRepo = chatRepo
    }
    
    public func myUserHandle() -> HandleEntity {
        chatRepo.myUserHandle()
    }
    
    public func monitorChatStatusChange() -> AnyPublisher<(HandleEntity, ChatStatusEntity), Never> {
        chatRepo.monitorChatStatusChange()
    }
    
    public func monitorChatListItemUpdate() -> AnyPublisher<[ChatListItemEntity], Never> {
        chatRepo.monitorChatListItemUpdate()
    }
    
    public func existsActiveCall() -> Bool {
        chatRepo.existsActiveCall()
    }
    
    public func activeCall() -> CallEntity? {
        chatRepo.activeCall()
    }

    public func fetchMeetings() -> [ChatListItemEntity]? {
        chatRepo.fetchMeetings()?.sorted(by: { $0.lastMessageDate.compare($1.lastMessageDate) == .orderedDescending })
    }
    
    public func fetchNonMeetings() -> [ChatListItemEntity]? {
        chatRepo.fetchNonMeetings()?.sorted(by: { $0.lastMessageDate.compare($1.lastMessageDate) == .orderedDescending })
    }
    
    public func fetchNoteToSelfChat() -> ChatRoomEntity? {
        chatRepo.fetchNoteToSelfChat()
    }
    
    public func createNoteToSelfChat() async throws -> ChatRoomEntity {
        try await chatRepo.createNoteToSelfChat()
    }
    
    public func isCallInProgress(for chatRoomId: HandleEntity) -> Bool {
        chatRepo.isCallInProgress(for: chatRoomId)
    }
    
    public func myFullName() -> String? {
        chatRepo.myFullName()
    }
    
    public func archivedChatListCount() -> UInt {
        chatRepo.archivedChatListCount()
    }
    
    public func unreadChatMessagesCount() -> Int {
        chatRepo.unreadChatMessagesCount()
    }
    
    public func chatConnectionStatus() -> ChatConnectionStatus {
        chatRepo.chatConnectionStatus()
    }
    
    public func chatConnectionStatus(for chatId: ChatIdEntity) async -> ChatConnectionStatus {
        chatRepo.chatConnectionStatus(for: chatId)
    }
    
    public func chatListItem(forChatId chatId: ChatIdEntity) -> ChatListItemEntity? {
        chatRepo.chatListItem(forChatId: chatId)
    }
    
    public func retryPendingConnections() {
        chatRepo.retryPendingConnections()
    }
    
    public func monitorChatCallStatusUpdate() -> AnyPublisher<CallEntity, Never> {
        chatRepo.monitorChatCallStatusUpdate()
    }
    
    public func monitorChatConnectionStatusUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatConnectionStatus, Never> {
        chatRepo.monitorChatConnectionStatusUpdate(forChatId: chatId)
    }
    
    public func monitorChatPrivateModeUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatRoomEntity, Never> {
        chatRepo.monitorChatPrivateModeUpdate(forChatId: chatId)
    }
    
    public func chatCall(for chatId: HandleEntity) async -> CallEntity? {
        chatRepo.chatCall(for: chatId)
    }
    
    public func isCallActive(for chatId: HandleEntity) -> Bool {
        chatRepo.isCallActive(for: chatId)
    }
    
    public func isActiveWaitingRoom(for chatId: HandleEntity) -> Bool {
        chatRepo.isActiveWaitingRoom(for: chatId)
    }
}
