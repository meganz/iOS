import MEGADomain
import MEGAFoundation
import MEGASwift

extension UploadFileRepository {
    /// Uploads every item of the selection, reporting the batch as a single transfer.
    ///
    /// Stands in for an SDK call that does not exist yet. A download batch is folded into one
    /// virtual transfer inside the SDK, by `MegaApi::startDownloadBatch`; there is no upload
    /// equivalent, so the fold is done here
    ///
    /// The fold follows the shape the SDK uses. Every item reports a `BatchUploadItemStatus` snapshot; all
    /// of them are merged into one aggregator, BatchUploadAggregator.
    ///
    /// What is folded is only whether the batch has started transferring: the whole selection is
    /// queued at once, so its items scan and build their trees at overlapping times and no count
    /// taken across them describes a stage the batch as a whole is in. So one folder update is
    /// reported, carrying the transferring stage, once every item has started; then a finish, once
    /// every item has ended. Losing every item of the batch is an error, and it is thrown rather
    /// than reported as a finish. Lost before any of them started, the batch reports no start at
    /// all; lost after, the start stands and only the finish is withheld.
    ///
    /// When the SDK does support a batch upload, this calls it directly, everything in the
    /// `BatchUpload` folder is deleted, and `CancellableUploadTransferUseCase` is not touched at
    /// all as it reads the batch as a stream of `TransferEventEntity`s either way.
    public func upload(batch: [UploadBatchItemEntity]) -> AnyAsyncThrowingSequence<TransferEventEntity, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                guard batch.isNotEmpty else {
                    MEGALog.log(level: .error, message: "[UploadFileRepository] upload batch is empty, nothing to upload")
                    continuation.finish(throwing: TransferErrorEntity.upload)
                    return
                }
                
                var aggregator = BatchUploadAggregator(batch: batch) { continuation.yield($0) }
                
                for await status in enqueue(batch: batch) {
                    guard !Task.isCancelled else { break }
                    do {
                        try aggregator.record(status)
                    } catch {
                        MEGALog.log(level: .error, message: "[UploadFileRepository] upload batch failed, every item of it failed: \(error)")
                        continuation.finish(throwing: error)
                        return
                    }
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in task.cancel() }
        }.eraseToAnyAsyncThrowingSequence()
    }
    
    // MARK: - Private
    private func enqueue(item: UploadBatchItemEntity, index: Int) -> AnyAsyncSequence<BatchUploadItemStatus> {
        AsyncStream(BatchUploadItemStatus.self) { continuation in
            let task = Task {
                do {
                    for try await event in upload(item) {
                        guard !Task.isCancelled else { break }
                        continuation.yield(BatchUploadItemStatus(index: index, isFile: item.isFile, phase: .transferring(event)))
                    }
                } catch {
                    MEGALog.log(level: .error, message: "[UploadFileRepository] upload item \(index) failed: \(error)")
                    continuation.yield(BatchUploadItemStatus(index: index, isFile: item.isFile, phase: .failed(error)))
                }
                
                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }.eraseToAnyAsyncSequence()
    }
    
    /// Merges every item of the batch into one channel of `BatchUploadItemStatus` snapshots.
    ///
    /// Deliberately not limit the maximum concurrent tasks here so all items are submitted to SDK at once
    /// The earlier SDK sends callback for them, the earlier BatchUploadAggregator can reach the terminal state.
    private func enqueue(batch: [UploadBatchItemEntity]) -> AnyAsyncSequence<BatchUploadItemStatus> {
        AsyncStream { continuation in
            let task = Task {
                await withTaskGroup { taskGroup in
                    for (index, item) in batch.enumerated() {
                        taskGroup.addTask {
                            for await status in enqueue(item: item, index: index) {
                                guard !Task.isCancelled else { break }
                                continuation.yield(status)
                            }
                        }
                    }
                }
                
                continuation.finish()
            }
            
            continuation.onTermination = { _ in task.cancel() }
        }.eraseToAnyAsyncSequence()
    }
}
