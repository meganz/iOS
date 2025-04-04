import MEGADomain
import MEGASdk

extension MEGAFolderInfo {
    public func toFolderInfoEntity() -> FolderInfoEntity {
        FolderInfoEntity(folderInfo: self)
    }
}

fileprivate extension FolderInfoEntity {
    init(folderInfo: MEGAFolderInfo) {
        self.init(
            versions: folderInfo.versions,
            files: folderInfo.files,
            folders: folderInfo.folders,
            currentSize: folderInfo.currentSize,
            versionsSize: folderInfo.versionsSize
        )
    }
}
