import MEGADomain
import MEGASdk

extension TransferEntity {
    init(transfer: MEGATransfer) {
        self.init(
            type: TransferTypeEntity(transferType: transfer.type) ?? .download,
            transferString: transfer.transferString,
            startTime: transfer.startTime,
            transferredBytes: Int(transfer.transferredBytes),
            totalBytes: Int(transfer.totalBytes),
            path: transfer.path,
            parentPath: transfer.parentPath,
            nodeHandle: transfer.nodeHandle,
            parentHandle: transfer.parentHandle,
            startPos: Int(transfer.startPos),
            endPos: Int(transfer.endPos),
            fileName: transfer.fileName,
            numRetry: transfer.numRetry,
            maxRetries: transfer.maxRetries,
            tag: transfer.tag,
            speed: Int(transfer.speed),
            deltaSize: Int(transfer.deltaSize),
            updateTime: transfer.updateTime,
            publicNode: transfer.publicNode?.toNodeEntity(),
            isStreamingTransfer: transfer.isStreamingTransfer,
            isFinished: transfer.isFinished,
            isForeignOverquota: transfer.isForeignOverquota,
            lastErrorExtended: transfer.lastErrorExtended?.toTransferErrorEntity(),
            isFolderTransfer: transfer.isFolderTransfer,
            folderTransferTag: transfer.folderTransferTag,
            appData: transfer.appData,
            state: TransferStateEntity(transferState: transfer.state) ?? .none,
            priority: transfer.priority,
            stage: TransferStageEntity(transferStage: transfer.stage) ?? .none
        )
    }
}
