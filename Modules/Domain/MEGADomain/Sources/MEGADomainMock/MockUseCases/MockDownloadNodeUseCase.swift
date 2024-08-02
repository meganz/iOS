import MEGADomain
import MEGASwift

public final class MockDownloadNodeUseCase: DownloadNodeUseCaseProtocol {
    private let transferEntity: TransferEntity?
    private let result: (Result<TransferEntity, TransferErrorEntity>)?
    private let transferError: TransferErrorEntity
    
    public init(transferEntity: TransferEntity? = nil,
                result: Result<TransferEntity, TransferErrorEntity>? = nil,
                transferError: TransferErrorEntity = .generic) {
        self.transferEntity = transferEntity
        self.result = result
        self.transferError = transferError
    }
    
    public func downloadFileToOffline(forNodeHandle handle: HandleEntity, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?, folderUpdate: ((FolderTransferUpdateEntity) -> Void)?) {
        guard let result = result else { return }
        completion?(result)
    }

    public func downloadFileToTempFolder(nodeHandle: HandleEntity, appData: String?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let transferEntity = transferEntity,
              let update = update else { return }
        update(transferEntity)
        guard let result = result else { return }
        completion(result)
    }
    
    public func downloadFileLinkToOffline(_ fileLink: FileLinkEntity, filename: String?, metaData: TransferMetaDataEntity?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let result = result else { return }
        completion(result)
    }
    
    public func cancelDownloadTransfers() { }
    
    public func downloadChatFileToOffline(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
