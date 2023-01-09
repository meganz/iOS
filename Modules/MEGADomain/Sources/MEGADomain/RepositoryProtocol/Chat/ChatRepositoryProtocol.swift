import Combine

public protocol ChatRepositoryProtocol {
    func myUserHandle() -> HandleEntity
    func isGuestAccount() -> Bool
    func chatStatus() -> ChatStatusEntity
    func changeChatStatus(to status: ChatStatusEntity)
    func monitorChatStatusChange() -> AnyPublisher<(HandleEntity, ChatStatusEntity), Never>
    func monitorChatListItemUpdate() -> AnyPublisher<[ChatListItemEntity], Never>
    func existsActiveCall() -> Bool
    func activeCall() -> CallEntity?
    func chatsList(ofType type: ChatTypeEntity) -> [ChatListItemEntity]?
    func scheduledMeetings() -> [ScheduledMeetingEntity]
    func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [ScheduledMeetingEntity]
    func isCallInProgress(for chatRoomId: HandleEntity) -> Bool
    func myFullName() -> String?
    func archivedChatListCount() -> UInt
    func unreadChatMessagesCount() -> Int
    func chatConnectionStatus() -> ChatConnectionStatus
    func chatListItem(forChatId chatId: ChatIdEntity) -> ChatListItemEntity?
    func retryPendingConnections()
    func monitorChatCallStatusUpdate() -> AnyPublisher<CallEntity, Never>
    func monitorChatConnectionStatusUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatConnectionStatus, Never> 
    func monitorChatPrivateModeUpdate(forChatId chatId: HandleEntity) -> AnyPublisher<ChatRoomEntity, Never>
}
