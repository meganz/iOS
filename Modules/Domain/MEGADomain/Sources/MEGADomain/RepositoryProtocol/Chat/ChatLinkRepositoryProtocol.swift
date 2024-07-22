import Combine

public protocol ChatLinkRepositoryProtocol: RepositoryProtocol, Sendable {
    func queryChatLink(for chatRoom: ChatRoomEntity) async throws -> String
    func createChatLink(for chatRoom: ChatRoomEntity) async throws -> String
    func removeChatLink(for chatRoom: ChatRoomEntity) async throws
    func queryChatLink(for chatRoom: ChatRoomEntity)
    func createChatLink(for chatRoom: ChatRoomEntity)
    func removeChatLink(for chatRoom: ChatRoomEntity)
    mutating func monitorChatLinkUpdate(for chatRoom: ChatRoomEntity) -> AnyPublisher<String?, Never>
}
