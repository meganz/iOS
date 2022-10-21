import Combine

public protocol ChatRepositoryProtocol {
    func chatStatus() -> ChatStatusEntity
    func changeChatStatus(to status: ChatStatusEntity)
    func monitorChatStatusChange(forUserHandle userHandle: HandleEntity) -> AnyPublisher<ChatStatusEntity, Never>
    func monitorChatListItemUpdate() -> AnyPublisher<ChatListItemEntity, Never>
    func existsActiveCall() -> Bool
    func activeCall() -> CallEntity?
    func chatsList(ofType type: ChatTypeEntity) -> [ChatListItemEntity]?
    func isCallInProgress(for chatRoomId: HandleEntity) -> Bool
    func myFullName() -> String?
    func archivedChatListCount() -> UInt
    func monitorChatCallStatusUpdate() -> AnyPublisher<CallEntity, Never>
}
