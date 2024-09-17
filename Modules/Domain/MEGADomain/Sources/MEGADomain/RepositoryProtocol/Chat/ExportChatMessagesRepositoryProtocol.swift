import Foundation

public protocol ExportChatMessagesRepositoryProtocol: RepositoryProtocol, Sendable {
    func exportText(message: ChatMessageEntity) -> URL?
    func exportContact(message: ChatMessageEntity, contactAvatarImage: String?, userFirstName: String?, userLastName: String?) -> URL?
}
