import Foundation
import MEGASwift

public protocol DownloadFileRepositoryProtocol: RepositoryProtocol, Sendable {
    // MARK: - normal download, to be removed when batch download is 100% rolled out.
    ///  Initiates download to save the given node handle to the passed in destination url.
    /// - Parameters:
    ///   - nodeHandle: Node Handle to be downloaded
    ///   - url: Location for file to be downloaded to.
    ///   - metaData: MetaData indicating type of download to start.
    /// - Returns: TransferEntity model on completion of download, else will throw TransferErrorEntity
    func download(
        nodeHandle: HandleEntity,
        to url: URL,
        metaData: TransferMetaDataEntity?
    ) async throws -> TransferEntity

    /// Downloads a folder node, reporting how many of the files inside it arrived.
    ///
    /// Separate from `download(nodeHandle:to:metaData:)` because a folder ending with an error is not the
    /// same as it having brought nothing down: the SDK reports a single incomplete transfer whatever the
    /// mix, so only the sub transfer counts say how much of it is usable.
    /// - Parameters:
    ///   - nodeHandle: Folder node handle to be downloaded.
    ///   - url: Location for the folder to be downloaded to.
    ///   - metaData: MetaData indicating type of download to start.
    /// - Returns: What the transfer ended up doing. Throws only when the transfer could not be run at
    ///   all, or when it was cancelled — a folder that ran and came back short is a result, not an error.
    func downloadFolder(
        nodeHandle: HandleEntity,
        to url: URL,
        metaData: TransferMetaDataEntity?
    ) async throws -> FolderDownloadResultEntity

    func downloadTo(
        _ url: URL,
        nodeHandle: HandleEntity,
        appData: String?
    ) throws -> AnyAsyncSequence<TransferEventEntity>
    
    func downloadFile(
        forNodeHandle handle: HandleEntity,
        to url: URL,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity>

    func downloadFileLink(
        _ fileLink: FileLinkEntity,
        named name: String,
        to url: URL,
        metaData: TransferMetaDataEntity?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity>
    
    // MARK: - batch download, which includes the transfer quota check
    
    /// Downloads a batch of nodes and reports the state of that batch.
    ///
    /// The whole selection goes down as a single transfer, so the events describe the batch and not
    /// the items in it: their folder updates count the batch's folders and files, and the
    /// transferring-files stage is reached once every item of it has started.
    ///
    /// - Parameter batch: Every root of the batch, each with its own destination.
    /// - Returns: The batch's transfer events. Asking for the sequence is what starts the batch.
    ///   A batch that got nowhere ends the sequence with the error that stopped it, rather than
    ///   reporting the failure as an event, which is what `CancellableTransferStateMapper` reads
    ///   as the batch having failed.
    func download(batch: [DownloadBatchItemEntity]) -> AnyAsyncThrowingSequence<TransferEventEntity, any Error>
    
    // MARK: - cancel download
    func cancelDownloadTransfers()
}
