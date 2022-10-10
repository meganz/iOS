import Combine

public protocol ChatRepositoryProtocol {
    func chatStatus() -> ChatStatusEntity
    func changeChatStatus(to status: ChatStatusEntity)
    func monitorSelfChatStatusChange() -> AnyPublisher<ChatStatusEntity, Never>
    func existsActiveCall() -> Bool
    func chatsList(ofType type: ChatTypeEntity) -> [ChatListItemEntity]?
}
