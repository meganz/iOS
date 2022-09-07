@testable import MEGA
import MEGADomain

struct MockDownloadFileRepository: DownloadFileRepositoryProtocol {
    static let newRepo = MockDownloadFileRepository()
    
    var completionResult: Result<TransferEntity, TransferErrorEntity> = .failure(.generic)
    var error: TransferErrorEntity = .generic
    var transferEntity: TransferEntity?
    
    func download(nodeHandle: HandleEntity, to url: URL, appData: String?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        completion(completionResult)
    }

    func downloadChat(nodeHandle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, to url: URL, appData: String?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        completion(completionResult)
    }
    
    func downloadTo(_ url: URL, nodeHandle: HandleEntity, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        completion(completionResult)
    }
    
    func downloadFile(forNodeHandle handle: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        completion?(completionResult)
    }
    
    func downloadChatFile(forNodeHandle handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        completion?(completionResult)
    }
    
    func downloadFileLink(_ fileLink: FileLinkEntity, named name: String, to url: URL, transferMetaData: TransferMetaDataEntity?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        completion?(completionResult)
    }
    
    func cancelDownloadTransfers() { }
}

