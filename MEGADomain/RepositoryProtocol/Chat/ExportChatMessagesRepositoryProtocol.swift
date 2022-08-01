import MEGADomain

protocol ExportChatMessagesRepositoryProtocol: RepositoryProtocol {
    func exportText(message: MEGAChatMessage) -> URL?
    func exportContact(message: MEGAChatMessage, contactAvatarImage: String?) -> URL?
}
