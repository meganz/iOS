import Foundation
import MEGAFoundation
import MEGASwift

// MARK: - Use case implementation

/// Uploads a batch of transfers, reporting the selection's progress rather than any one item's.
///
/// The `.upload` implementation of `CancellableTransferUseCaseProtocol`, and the mirror of
/// `CancellableDownloadTransferUseCase`.
///
///  The SDK has no `startUploadBatch` yet, so `UploadFileRepository` stands in for one.
///  When the SDK gains it, that shim is deleted and this type is not touched,
///  because it already reads the batch the way the SDK will report it.
public struct CancellableUploadTransferUseCase: CancellableTransferUseCaseProtocol {
    // MARK: - Dependencies

    private let uploadFileRepository: any UploadFileRepositoryProtocol
    private let mapper: any CancellableTransferStateMapping
    
    public init(
        uploadFileRepository: some UploadFileRepositoryProtocol,
        mapper: some CancellableTransferStateMapping = CancellableTransferStateMapper(direction: .upload)
    ) {
        self.uploadFileRepository = uploadFileRepository
        self.mapper = mapper
    }

    // MARK: - Batch upload

    public func start(transfers: [CancellableTransferEntity]) -> AnyAsyncSequence<CancellableTransferStateEntity> {
        let batch = transfers.compactMap(\.uploadBatchItemEntity)
        
        MEGALog.log(
            level: .info,
            message: "[CancellableTransfer] uploading batch of \(batch.count) item(s), \(batch.filter(\.isFile).count) of them files"
        )

        return mapper.map(from: { [uploadFileRepository] in uploadFileRepository.upload(batch: batch) })
    }

    public func cancel() {
        MEGALog.log(level: .info, message: "[CancellableTransfer] cancelling the upload batch")
        uploadFileRepository.cancelUploadTransfers()
    }
}

private extension CancellableTransferEntity {
    var uploadBatchItemEntity: UploadBatchItemEntity? {
        guard type == .upload, let localFileURL, let uploadOptions else { return nil }
        return UploadBatchItemEntity(
            localFileURL: localFileURL,
            parentHandle: parentHandle,
            isFile: isFile,
            options: uploadOptions
        )
    }
}
