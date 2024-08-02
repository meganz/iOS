import Foundation
import MEGASwift

public protocol DownloadChatRepositoryProtocol: RepositoryProtocol {
    /// Downloads a chat message from the specified node, given the message ID and chat ID, and saves it to the specified URL.
    /// - Parameters:
    ///   - nodeHandle: The handle of the node associated with the chat file.
    ///   - messageId: The handle of the chat message to download.
    ///   - chatId: The handle of the chat where the message belongs.
    ///   - url: The URL where the downloaded chat message will be saved.
    ///   - metaData: Optional metadata associated with the transfer.
    /// - Returns: A `TransferEntity` representing the ongoing transfer.
    /// - Throws: An error if the download operation fails.
    func downloadChat(
        nodeHandle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to url: URL,
        metaData: TransferMetaDataEntity?
    ) async throws -> TransferEntity
    
    /// Downloads a chat file for a given node handle, message ID, and chat ID to a specified URL.
    /// - Parameters:
    ///   - handle: The handle of the node associated with the chat file.
    ///   - messageId: The handle of the chat message to download.
    ///   - chatId: The handle of the chat where the message belongs.
    ///   - url: The URL where the downloaded chat message will be saved.
    ///   - filename: The name of the downloaded chat file. Optional.
    ///   - appdata: Additional application-specific data associated with the chat file. Optional.
    ///   - startFirst: A boolean value indicating whether to start the transfer immediately.
    ///   - start:  A closure that is called when the transfer starts. It takes a `TransferEntity` parameter.
    ///   - update: A closure that is called when the transfer updates. It takes a `TransferEntity` parameter.
    /// - Returns: AnyAsyncSequence<[TransferEventEntity]> of transfer events, yields when: transfer starts, transfer updates (progress) and transfer finishes
    /// - Throws: An error if the download operation fails.
    func downloadChatFile(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to url: URL,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity>
}
