import Foundation

public protocol ChatRoomUserRepositoryProtocol: RepositoryProtocol, Sendable {
    func userFullName(forPeerId peerId: HandleEntity, chatRoom: ChatRoomEntity) async throws -> String
    func contactEmail(forUserHandle userHandle: HandleEntity) -> String?
}
