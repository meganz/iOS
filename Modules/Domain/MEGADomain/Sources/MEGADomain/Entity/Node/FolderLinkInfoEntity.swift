public struct FolderLinkInfoEntity: Equatable, Sendable {
    public let folderInfo: FolderInfoEntity?
    public let nodeHandle: HandleEntity
    public let parentHandle: HandleEntity
    public let name: String?
    
    public init(folderInfo: FolderInfoEntity?, nodeHandle: HandleEntity, parentHandle: HandleEntity, name: String?) {
        self.folderInfo = folderInfo
        self.nodeHandle = nodeHandle
        self.parentHandle = parentHandle
        self.name = name
    }
}
