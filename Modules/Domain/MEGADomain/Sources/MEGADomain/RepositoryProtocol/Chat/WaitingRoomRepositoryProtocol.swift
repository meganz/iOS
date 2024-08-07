import Foundation

public protocol WaitingRoomRepositoryProtocol: RepositoryProtocol, Sendable {
    func userName() -> String
    func joinChat(forChatId chatId: UInt64, userHandle: UInt64) async throws -> ChatRoomEntity
}
