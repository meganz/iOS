import Foundation

/// One root of a batch download: what to download, where it is stored and how it is queued.
///
/// Handed to `DownloadFileRepositoryProtocol.download(batch:)`, which downloads the whole selection as a single transfer
public struct DownloadBatchItemEntity: Sendable {
    /// What the item downloads, and with it what the data layer has to resolve to reach the node.
    public enum Source: Sendable {
        /// A node of the account, or of the folder link the batch is being downloaded from.
        case node(HandleEntity)
        /// A chat attachment, resolved through the message it was attached to and authorised
        /// against the chat room when that room is only being previewed.
        case chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity)
        /// A public file link, resolved to the single file it points at.
        case fileLink(FileLinkEntity)
    }

    public let source: Source
    public let destinationFolder: URL
    public let name: String?
    public let appData: String?
    public let startFirst: Bool

    public init(
        source: Source,
        destinationFolder: URL,
        name: String? = nil,
        appData: String? = nil,
        startFirst: Bool = false
    ) {
        self.source = source
        self.destinationFolder = destinationFolder
        self.name = name
        self.appData = appData
        self.startFirst = startFirst
    }
}
