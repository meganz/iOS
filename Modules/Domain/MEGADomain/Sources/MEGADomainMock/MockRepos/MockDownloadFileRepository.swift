import Foundation
import MEGADomain
import MEGASwift

public struct MockDownloadFileRepository: DownloadFileRepositoryProtocol {
    
    public static let newRepo = MockDownloadFileRepository()
    
    private let completionResult: Result<TransferEntity, TransferErrorEntity>
    private let error: TransferErrorEntity
    private let transferEntity: TransferEntity?
    private let folderDownloadResult: Result<FolderDownloadResultEntity, TransferErrorEntity>

    public init(completionResult: Result<TransferEntity, TransferErrorEntity> = .failure(.generic),
                error: TransferErrorEntity = .generic,
                transferEntity: TransferEntity? = nil,
                folderDownloadResult: Result<FolderDownloadResultEntity, TransferErrorEntity> = .failure(.generic)) {
        self.completionResult = completionResult
        self.error = error
        self.transferEntity = transferEntity
        self.folderDownloadResult = folderDownloadResult
    }

    public func download(nodeHandle: HandleEntity, to url: URL, metaData: TransferMetaDataEntity?) async throws -> TransferEntity {
        try await withCheckedThrowingContinuation { continuation in continuation.resume(with: completionResult) }
    }

    public func downloadFolder(
        nodeHandle: HandleEntity,
        to url: URL,
        metaData: TransferMetaDataEntity?
    ) async throws -> FolderDownloadResultEntity {
        try folderDownloadResult.get()
    }

    public func downloadTo(_ url: URL, nodeHandle: HandleEntity, appData: String?) throws -> AnyAsyncSequence<TransferEventEntity> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    public func downloadFile(forNodeHandle handle: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool) throws -> AnyAsyncSequence<TransferEventEntity> {
        try proceedDownload()
    }
    
    public func downloadFileLink(
        _ fileLink: FileLinkEntity,
        named name: String,
        to url: URL,
        metaData: TransferMetaDataEntity?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        try proceedDownload()
    }
    
    public func cancelDownloadTransfers() { }
    
    // MARK: Private
    private func proceedDownload() throws -> AnyAsyncSequence<TransferEventEntity> {
        switch completionResult {
        case .success(let transferEntity):
            AsyncThrowingStream(TransferEventEntity.self) { continuation in
                continuation.yield(.start(transferEntity))
                continuation.yield(.update(transferEntity))
                continuation.yield(.finish(transferEntity))
                continuation.finish()
            }.eraseToAnyAsyncSequence()
        case .failure(let error):
            throw error
        }
    }
}
