import Combine

public protocol ChatRepositoryProtocol: RepositoryProtocol, Sendable {
    func myUserHandle() -> HandleEntity
    func chatStatus() -> ChatStatusEntity
    func changeChatStatus(to status: ChatStatusEntity)
    func monitorChatStatusChange() -> AnyPublisher<(HandleEntity, ChatStatusEntity), Never>
    func monitorChatListItemUpdate() -> AnyPublisher<[ChatListItemEntity], Never>
    func monitorChatListItemSingleUpdate() -> AnyPublisher<ChatListItemEntity, Never>
    func existsActiveCall() -> Bool
    func activeCall() -> CallEntity?
    func fetchMeetings() -> [ChatListItemEntity]?
    func fetchNonMeetings() -> [ChatListItemEntity]?
    func isCallInProgress(for chatRoomId: HandleEntity) -> Bool
    func myFullName() -> String?
    func archivedChatListCount() -> UInt
    func unreadChatMessagesCount() -> Int
    func chatConnectionStatus() -> ChatConnectionStatus
    func chatConnectionStatus(for chatId: ChatIdEntity) -> ChatConnectionStatus
    func chatListItem(forChatId chatId: ChatIdEntity) -> ChatListItemEntity?
    func retryPendingConnections()
    func monitorChatCallStatusUpdate() -> AnyPublisher<CallEntity, Never>
    func monitorChatCallUpdate() -> AnyPublisher<CallEntity, Never>
    func monitorChatCallUpdate(for callId: HandleEntity, changeTypes: Set<CallEntity.ChangeType>) -> AnyPublisher<CallEntity, Never>
    func monitorChatConnectionStatusUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatConnectionStatus, Never>
    func monitorChatPrivateModeUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatRoomEntity, Never>
    func chatCall(for chatId: HandleEntity) -> CallEntity?
    func isCallActive(for chatId: HandleEntity) -> Bool
    func isActiveWaitingRoom(for chatId: HandleEntity) -> Bool
    func listenForChatOnline(_ chatId: HandleEntity) async
    func listenForCallAvailability(_ chatId: HandleEntity) async
}
