public struct FolderTransferUpdateEntity: Sendable {
    public let transfer: TransferEntity
    public let stage: TransferStageEntity
    public let folderCount: UInt
    public let createdFolderCount: UInt
    public let fileCount: UInt
    
    public init(transfer: TransferEntity, stage: TransferStageEntity, folderCount: UInt, createdFolderCount: UInt, fileCount: UInt) {
        self.transfer = transfer
        self.stage = stage
        self.folderCount = folderCount
        self.createdFolderCount = createdFolderCount
        self.fileCount = fileCount
    }
}
