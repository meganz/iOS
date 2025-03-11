import Combine

public protocol ChatRepositoryProtocol: RepositoryProtocol, Sendable {
    func myUserHandle() -> HandleEntity
    func monitorChatStatusChange() -> AnyPublisher<(HandleEntity, ChatStatusEntity), Never>
    func monitorChatListItemUpdate() -> AnyPublisher<[ChatListItemEntity], Never>
    func existsActiveCall() -> Bool
    func activeCall() -> CallEntity?
    func fetchMeetings() -> [ChatListItemEntity]?
    func fetchNonMeetings() -> [ChatListItemEntity]?
    func fetchNoteToSelfChat() -> ChatRoomEntity?
    func createNoteToSelfChat() async throws -> ChatRoomEntity
    func isCallInProgress(for chatRoomId: HandleEntity) -> Bool
    func myFullName() -> String?
    func archivedChatListCount() -> UInt
    func unreadChatMessagesCount() -> Int
    func chatConnectionStatus() -> ChatConnectionStatus
    func chatConnectionStatus(for chatId: ChatIdEntity) -> ChatConnectionStatus
    func chatListItem(forChatId chatId: ChatIdEntity) -> ChatListItemEntity?
    func retryPendingConnections()
    func monitorChatCallStatusUpdate() -> AnyPublisher<CallEntity, Never>
    func monitorChatConnectionStatusUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatConnectionStatus, Never> 
    func monitorChatPrivateModeUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatRoomEntity, Never>
    func chatCall(for chatId: HandleEntity) -> CallEntity?
    func isCallActive(for chatId: HandleEntity) -> Bool
    func isActiveWaitingRoom(for chatId: HandleEntity) -> Bool
}
