import MEGADomain

public extension FolderLinkInfoEntity {
    init(
        folderInfo: FolderInfoEntity? = nil,
        nodeHandle: HandleEntity = .invalid,
        parentHandle: HandleEntity = .invalid,
        name: String? = nil,
        isTesting: Bool = true
    ) {
        self.init(
            folderInfo: folderInfo,
            nodeHandle: nodeHandle,
            parentHandle: parentHandle,
            name: name
        )
    }
}
