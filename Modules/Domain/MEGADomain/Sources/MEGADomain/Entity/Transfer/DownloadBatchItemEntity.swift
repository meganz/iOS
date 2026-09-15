import Foundation

/// One item of a batch download: what to download, where it is stored and how it is queued.
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
    /// Where the item is stored, and under what name.
    public let destination: DownloadDestinationEntity
    public let appData: String?
    public let startFirst: Bool

    public init(
        source: Source,
        destination: DownloadDestinationEntity,
        appData: String? = nil,
        startFirst: Bool = false
    ) {
        self.source = source
        self.destination = destination
        self.appData = appData
        self.startFirst = startFirst
    }
}
