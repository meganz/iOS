import Foundation

public struct TransferEntity {
    
    // MARK: - Types
    
    public let type: TransferTypeEntity
    public let transferString: String?
    
    // MARK: - Attributes
    
    public let startTime: Date?
    public let transferredBytes: Int
    public let totalBytes: Int
    public let path: String?
    public let parentPath: String?
    public let nodeHandle: HandleEntity
    public let parentHandle: HandleEntity
    public let startPos: Int?
    public let endPos: Int?
    public let fileName: String?
    public let numRetry: Int
    public let maxRetries: Int
    public let tag: Int
    public let speed: Int
    public let deltaSize: Int?
    public let updateTime: Date?
    public let publicNode: NodeEntity?
    public let isStreamingTransfer: Bool
    public let isForeignOverquota: Bool
    public let lastErrorExtended: TransferErrorEntity?
    public let isFolderTransfer: Bool
    public let folderTransferTag: Int
    public let appData: String?
    public let state: TransferStateEntity
    public let priority: UInt64
    public let stage: TransferStageEntity
    
    public init(type: TransferTypeEntity, transferString: String?, startTime: Date?, transferredBytes: Int, totalBytes: Int, path: String?, parentPath: String?, nodeHandle: HandleEntity, parentHandle: HandleEntity, startPos: Int?, endPos: Int?, fileName: String?, numRetry: Int, maxRetries: Int, tag: Int, speed: Int, deltaSize: Int?, updateTime: Date?, publicNode: NodeEntity?, isStreamingTransfer: Bool, isForeignOverquota: Bool, lastErrorExtended: TransferErrorEntity?, isFolderTransfer: Bool, folderTransferTag: Int, appData: String?, state: TransferStateEntity, priority: UInt64, stage: TransferStageEntity) {
        self.type = type
        self.transferString = transferString
        self.startTime = startTime
        self.transferredBytes = transferredBytes
        self.totalBytes = totalBytes
        self.path = path
        self.parentPath = parentPath
        self.nodeHandle = nodeHandle
        self.parentHandle = parentHandle
        self.startPos = startPos
        self.endPos = endPos
        self.fileName = fileName
        self.numRetry = numRetry
        self.maxRetries = maxRetries
        self.tag = tag
        self.speed = speed
        self.deltaSize = deltaSize
        self.updateTime = updateTime
        self.publicNode = publicNode
        self.isStreamingTransfer = isStreamingTransfer
        self.isForeignOverquota = isForeignOverquota
        self.lastErrorExtended = lastErrorExtended
        self.isFolderTransfer = isFolderTransfer
        self.folderTransferTag = folderTransferTag
        self.appData = appData
        self.state = state
        self.priority = priority
        self.stage = stage
    }
}
