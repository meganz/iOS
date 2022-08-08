@testable import MEGA
import MEGADomain

struct MockDownloadFileRepository: DownloadFileRepositoryProtocol {
    static let newRepo = MockDownloadFileRepository()
    
    var completionResult: Result<TransferEntity, TransferErrorEntity> = .failure(.generic)
    var error: TransferErrorEntity = .generic
    var transferEntity: TransferEntity?
    
    func download(nodeHandle: HandleEntity, to path: String, appData: String?, cancelToken: MEGACancelToken?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        completion(completionResult)
    }

    func downloadChat(nodeHandle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, to path: String, appData: String?, cancelToken: MEGACancelToken?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        completion(completionResult)
    }
    
    func downloadToTempFolder(nodeHandle: HandleEntity, appData: String?, cancelToken: MEGACancelToken?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        completion(completionResult)
    }
    
    func downloadTo(folderPath: String, nodeHandle: HandleEntity, appData: String?, cancelToken: MEGACancelToken?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        completion(completionResult)
    }
    
    func downloadFile(forNodeHandle handle: HandleEntity, toUrl url: URL, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        completion?(completionResult)
    }
    
    func downloadChatFile(forNodeHandle handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, toUrl url: URL, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        completion?(completionResult)
    }
    
    func downloadFileLink(_ fileLink: FileLinkEntity, named name: String, toUrl url: URL, transferMetaData: TransferMetaDataEntity?, startFirst: Bool, cancelToken: MEGACancelToken?) async throws -> TransferEntity {
        if let transferEntity = transferEntity {
            return transferEntity
        } else {
            throw error
        }
    }
}

