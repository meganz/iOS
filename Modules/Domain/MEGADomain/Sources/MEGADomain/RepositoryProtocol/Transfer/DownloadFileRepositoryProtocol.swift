import Foundation
import MEGASwift

public protocol DownloadFileRepositoryProtocol: RepositoryProtocol, Sendable {
    
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
    
    func cancelDownloadTransfers()
}
