import Foundation

public protocol DownloadFileRepositoryProtocol: RepositoryProtocol {
    func download(nodeHandle: HandleEntity, to url: URL, appData: String?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func downloadChat(nodeHandle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, to url: URL, appData: String?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func downloadTo(_ url: URL, nodeHandle: HandleEntity, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func downloadFile(forNodeHandle handle: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, folderUpdate: ((FolderTransferUpdateEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?)
    func downloadChatFile(forNodeHandle handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?)
    func downloadFileLink(_ fileLink: FileLinkEntity, named name: String, to url: URL, transferMetaData: TransferMetaDataEntity?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?)
    func cancelDownloadTransfers()
}
