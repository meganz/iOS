extension TransferEntity {
    init(transfer: MEGATransfer) {
        
        // MARK: - Types
        
        self.type = TransferTypeEntity(transferType: transfer.type)!
        self.transferString = transfer.transferString
        
        // MARK: - Attributes
        
        self.startTime = transfer.startTime
        self.transferredBytes = transfer.transferredBytes?.intValue ?? 0
        self.totalBytes = transfer.totalBytes?.intValue ?? 0
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
        self.speed = transfer.speed?.intValue ?? 0
        self.deltaSize = transfer.deltaSize.intValue
        self.updateTime = transfer.updateTime
        if let node = transfer.publicNode {
            self.publicNode = node.toNodeEntity()
        } else {
            self.publicNode = nil
        }
        self.isStreamingTransfer = transfer.isStreamingTransfer
        self.isForeignOverquota = transfer.isForeignOverquota
       
        if transfer.lastErrorExtended != nil {
            switch transfer.lastErrorExtended.type {
            case .apiOk:
                self.lastErrorExtended = nil
            case .apiEOverQuota:
                self.lastErrorExtended = .overquota
            default:
                self.lastErrorExtended = .generic
            }
        } else {
            self.lastErrorExtended = nil
        }
        
        self.isFolderTransfer = transfer.isFolderTransfer
        self.folderTransferTag = transfer.folderTransferTag
        self.appData = transfer.appData
        self.state = TransferStateEntity.init(transferState: transfer.state)!
        self.priority = transfer.priority
        self.stage = TransferStageEntity.init(transferStage: transfer.stage) ?? .none
    }
    
    func toMEGATransfer(in sdk: MEGASdk) -> MEGATransfer? {
        sdk.transfer(byTag: self.tag)
    }

}
