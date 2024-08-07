import Foundation

public protocol DownloadFileRepositoryProtocol: RepositoryProtocol, Sendable {
    
    ///  Initiates download to save the given node handle to the passed in destination url.
    /// - Parameters:
    ///   - nodeHandle: Node Handle to be downloaded
    ///   - url: Location for file to be downloaded to.
    ///   - metaData: MetaData indicating type of download to start.
    /// - Returns: TransferEntity model on completion of download, else will throw TransferErrorEntity
    func download(nodeHandle: HandleEntity, to url: URL, metaData: TransferMetaDataEntity?) async throws -> TransferEntity
    
    func download(nodeHandle: HandleEntity, to url: URL, metaData: TransferMetaDataEntity?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    
    func downloadTo(_ url: URL, nodeHandle: HandleEntity, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func downloadFile(forNodeHandle handle: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, folderUpdate: ((FolderTransferUpdateEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?)
    func downloadFileLink(_ fileLink: FileLinkEntity, named name: String, to url: URL, metaData: TransferMetaDataEntity?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?)
    func cancelDownloadTransfers()
}
