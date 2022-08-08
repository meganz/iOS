import MEGADomain

extension TransferEntity {
    fileprivate init(transfer: MEGATransfer) {
        self.init(
            type: TransferTypeEntity(transferType: transfer.type) ?? .download,
            transferString: transfer.transferString,
            startTime: transfer.startTime,
            transferredBytes: transfer.transferredBytes?.intValue ?? 0,
            totalBytes: transfer.totalBytes?.intValue ?? 0,
            path: transfer.path,
            parentPath: transfer.parentPath,
            nodeHandle: transfer.nodeHandle,
            parentHandle: transfer.parentHandle,
            startPos: transfer.startPos.intValue,
            endPos: transfer.endPos.intValue,
            fileName: transfer.fileName,
            numRetry: transfer.numRetry,
            maxRetries: transfer.maxRetries,
            tag: transfer.tag,
            speed: transfer.speed?.intValue ?? 0,
            deltaSize: transfer.deltaSize.intValue,
            updateTime: transfer.updateTime,
            publicNode: transfer.publicNode?.toNodeEntity(),
            isStreamingTransfer: transfer.isStreamingTransfer,
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
    
    func toMEGATransfer(in sdk: MEGASdk) -> MEGATransfer? {
        sdk.transfer(byTag: self.tag)
    }
}

extension MEGATransfer {
    func toTransferEntity() -> TransferEntity {
        TransferEntity(transfer: self)
    }
}
