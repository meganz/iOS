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
///
///  Each item is first moved into the Uploads folder, like the legacy `UploadFileUseCase`.
///  A Files pick lives in `tmp/<bundle>-Inbox`, and iOS removes it about 60 s later.
///  The moved items are removed only when the SDK is done with the whole batch.
///  So that clean up keeps reading the upload after the screen stops listening.
public struct CancellableUploadTransferUseCase: CancellableTransferUseCaseProtocol {
    // MARK: - Dependencies

    private let uploadFileRepository: any UploadFileRepositoryProtocol
    private let fileSystemRepository: any FileSystemRepositoryProtocol
    private let fileCacheRepository: any FileCacheRepositoryProtocol
    private let mapper: any CancellableTransferStateMapping
    
    public init(
        uploadFileRepository: some UploadFileRepositoryProtocol,
        fileSystemRepository: some FileSystemRepositoryProtocol,
        fileCacheRepository: some FileCacheRepositoryProtocol,
        mapper: some CancellableTransferStateMapping = CancellableTransferStateMapper(direction: .upload)
    ) {
        self.uploadFileRepository = uploadFileRepository
        self.fileSystemRepository = fileSystemRepository
        self.fileCacheRepository = fileCacheRepository
        self.mapper = mapper
    }

    // MARK: - Batch upload

    public func start(transfers: [CancellableTransferEntity]) -> AnyAsyncSequence<CancellableTransferStateEntity> {
        let batch = transfers.compactMap(\.uploadBatchItemEntity)
        
        MEGALog.log(
            level: .info,
            message: "[CancellableTransfer] uploading batch of \(batch.count) item(s), \(batch.filter(\.isFile).count) of them files"
        )

        var movedBatch = [UploadBatchItemEntity]()
        for item in batch {
            let name = item.options.fileName ?? item.localFileURL.lastPathComponent
            let uploadURL = fileCacheRepository.tempUploadURL(for: name)
            guard fileSystemRepository.moveFile(at: item.localFileURL, to: uploadURL) else {
                MEGALog.log(level: .error, message: "[CancellableTransfer] failed to move \(name) into the Uploads folder")
                movedBatch.forEach { try? fileSystemRepository.removeItem(at: $0.localFileURL) }
                return AsyncStream { continuation in
                    continuation.yield(.failed)
                    continuation.finish()
                }.eraseToAnyAsyncSequence()
            }
            movedBatch.append(
                UploadBatchItemEntity(
                    localFileURL: uploadURL,
                    parentHandle: item.parentHandle,
                    isFile: item.isFile,
                    options: item.options
                )
            )
        }

        return mapper.map(from: { [movedBatch] in relayedUpload(of: movedBatch) })
    }

    public func cancel() {
        MEGALog.log(level: .info, message: "[CancellableTransfer] cancelling the upload batch")
        uploadFileRepository.cancelUploadTransfers()
    }

    // MARK: - Private

    /// Keeps reading the upload after the mapper stops at the transferring stage.
    /// So the moved items are removed only when the SDK has finished with all of them.
    private func relayedUpload(of batch: [UploadBatchItemEntity]) -> AnyAsyncThrowingSequence<TransferEventEntity, any Error> {
        AsyncThrowingStream { [uploadFileRepository, fileSystemRepository] continuation in
            // No onTermination cancel: the relay must outlive the screen.
            Task {
                // The sync removeItem, because an async one does nothing in a cancelled task.
                defer { batch.forEach { try? fileSystemRepository.removeItem(at: $0.localFileURL) } }
                do {
                    for try await event in uploadFileRepository.upload(batch: batch) {
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }.eraseToAnyAsyncThrowingSequence()
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
