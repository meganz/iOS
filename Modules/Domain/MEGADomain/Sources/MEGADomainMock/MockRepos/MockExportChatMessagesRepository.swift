import Foundation
import MEGADomain

public struct MockExportChatMessagesRepository: ExportChatMessagesRepositoryProtocol {
    public static let newRepo = MockExportChatMessagesRepository()

    private let textURL: URL?
    private let contactURL: URL?

    public init(textURL: URL? = nil, contactURL: URL? = nil) {
        self.textURL = textURL
        self.contactURL = contactURL
    }

    public func exportText(message: ChatMessageEntity) -> URL? {
        textURL
    }

    public func exportContact(
        message: ChatMessageEntity,
        contactAvatarImage: String?,
        userFirstName: String?,
        userLastName: String?
    ) -> URL? {
        contactURL
    }
}
