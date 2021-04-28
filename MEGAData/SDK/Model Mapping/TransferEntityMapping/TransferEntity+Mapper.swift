extension TransferEntity {
    init(transfer: MEGATransfer) {
        
        // MARK: - Types
        
        self.type = TransferTypeEntity(transferType: transfer.type)!
        self.transferString = transfer.transferString
        
        // MARK: - Attributes
        
        self.startTime = transfer.startTime
        self.transferredBytes = transfer.transferredBytes.floatValue
        self.totalBytes = transfer.totalBytes.floatValue
        self.path = transfer.path
        self.parentPath = transfer.parentPath
        self.nodeHandle = transfer.nodeHandle
        self.parentHandle = transfer.parentHandle
        self.startPos = transfer.startPos.intValue
        self.endPos = transfer.endPos.intValue
        self.fileName = transfer.fileName
        self.numRetry = transfer.numRetry
        self.maxRetries = transfer.maxRetries
        self.tag = transfer.tag
        self.speed = transfer.speed.intValue
        self.deltaSize = transfer.deltaSize.intValue
        self.updateTime = transfer.updateTime
        if let node = transfer.publicNode {
            self.publicNode = NodeEntity(node: node)
        } else {
            self.publicNode = nil
        }
        self.isStreamingTransfer = transfer.isStreamingTransfer
        self.isFolderTransfer = transfer.isFolderTransfer
        self.folderTransferTag = transfer.folderTransferTag
        self.appData = transfer.appData
        self.state = TransferStateEntity.init(transferState: transfer.state)!
        self.priority = transfer.priority
    }
}
