struct TransferEntity {
    
    // MARK: - Types
    
    let type: TransferTypeEntity
    let transferString: String?
    
    // MARK: - Attributes
    
    let startTime: Date?
    let transferredBytes: Int
    let totalBytes: Int
    let path: String?
    let parentPath: String?
    let nodeHandle: MEGAHandle
    let parentHandle: MEGAHandle
    let startPos: Int?
    let endPos: Int?
    let fileName: String?
    let numRetry: Int
    let maxRetries: Int
    let tag: Int
    let speed: Int
    let deltaSize: Int?
    let updateTime: Date?
    let publicNode: NodeEntity?
    let isStreamingTransfer: Bool
    let isForeignOverquota: Bool
    let lastErrorExtended: TransferErrorEntity?
    let isFolderTransfer: Bool
    let folderTransferTag: Int
    let appData: String?
    let state: TransferStateEntity
    let priority: UInt64
    let stage: TransferStageEntity
}
