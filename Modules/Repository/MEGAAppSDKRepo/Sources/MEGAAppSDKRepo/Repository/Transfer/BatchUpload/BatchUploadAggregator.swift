import MEGADomain
import MEGAFoundation

extension TransferEntity {
    fileprivate static var virtualBatchUploadTransferEntity: TransferEntity {
        TransferEntity(
            type: .upload,
            transferString: nil,
            startTime: nil,
            transferredBytes: 0,
            totalBytes: 0,
            path: nil,
            parentPath: nil,
            nodeHandle: .invalid,
            parentHandle: .invalid,
            startPos: 0,
            endPos: 0,
            fileName: nil,
            numRetry: 0,
            maxRetries: 0,
            tag: -1,
            speed: 0,
            deltaSize: nil,
            updateTime: nil,
            publicNode: nil,
            isStreamingTransfer: false,
            isFinished: false,
            isForeignOverquota: false,
            lastErrorExtended: nil,
            isFolderTransfer: true,
            folderTransferTag: -1,
            appData: nil,
            state: .none,
            priority: 0,
            stage: .none
        )
    }
}

/// Folds every item's `BatchUploadItemStatus` into the batch's own transfer events.
///
/// What is folded is only whether the batch is away: one folder update carrying the transferring
/// stage, once every item has started, then a finish, once every item has ended.
///
/// A batch whose every item failed early without starting transferring, `record` throws instead of reporting the batch finished.
struct BatchUploadAggregator: Sendable {
    // The single transfer entity representing the batch transfer
    private var transferEntity: TransferEntity
    private var items: [BatchUploadItemStatus] = []
    private let updateHandler: @Sendable (TransferEventEntity) -> Void
    private var didReportHandover = false
    /// The items that have been away at some point, and the ones that have ended.
    ///
    /// Remembered rather than counted off `items`, because an item reports where it stands as of
    /// its last callback, so an item counted as `hasStarted` = true at this point could be changed back to false later.
    /// Why: a folder that has reached its transferring stage (onFolderUpdate) goes on reporting bytes on its own
    /// virtual transfer (onUpdate), and those updates carry no stage at all.
    private var startedIndices: Set<Int> = []
    private var finishedIndices: Set<Int> = []
    
    private var hasStarted: Bool {
        startedIndices.count == items.count
    }
    
    private var hasFinished: Bool {
        finishedIndices.count == items.count
    }
    
    init(
        batch: [UploadBatchItemEntity],
        updateHandler: @Sendable @escaping (TransferEventEntity) -> Void
    ) {
        self.transferEntity = TransferEntity.virtualBatchUploadTransferEntity
        self.updateHandler = updateHandler
        self.items = batch.enumerated().map {
            BatchUploadItemStatus(index: $0.offset, isFile: $0.element.isFile, phase: .none)
        }
        
        updateHandler(.start(transferEntity))
    }
    
    mutating func record(_ status: BatchUploadItemStatus) throws {
        items[status.index] = status
        if status.hasStartedTransferring {
            startedIndices.insert(status.index)
        }
        if status.hasFinishedTransferring {
            finishedIndices.insert(status.index)
        }

        // Checked before anything is reported: a failed item counts as started, having nothing
        // left to wait for, so a batch whose every item failed satisfies `hasStarted` too.
        let errors = items.compactMap(\.error)
        if errors.count == items.count, let error = errors.first {
            throw error
        }

        // If every item in the batch has started transferring, report the folder update with stage .transferringFiles
        if hasStarted && !didReportHandover {
            didReportHandover = true
            MEGALog.log(
                level: .info,
                message: "[UploadFileRepository] upload batch handed over: all \(items.count) item(s) started"
            )
            updateHandler(
                .folderUpdate(
                    FolderTransferUpdateEntity(
                        transfer: transferEntity,
                        stage: .transferringFiles,
                        folderCount: 0,
                        createdFolderCount: 0,
                        fileCount: 0
                    )
                )
            )
        }

        // Every item in the batch has finished transferring, either succeeded or failed.
        if hasFinished {
            MEGALog.log(level: .info, message: "[UploadFileRepository] upload batch finished: all \(items.count) item(s) ended")
            updateHandler(.finish(transferEntity))
        }
    }
}
