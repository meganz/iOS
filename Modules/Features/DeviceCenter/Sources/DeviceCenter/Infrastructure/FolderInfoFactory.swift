import MEGADomain

/// `FolderInfoFactory` is responsible for creating `FolderInfo` objects which summarize the contents of folders represented by backup entities. It uses a `NodeUseCaseProtocol` to access and manipulate node data.
struct FolderInfoFactory {
    var nodeUseCase: any NodeUseCaseProtocol
    
    init(nodeUseCase: some NodeUseCaseProtocol) {
        self.nodeUseCase = nodeUseCase
    }
    
    /// Asynchronously generates `FolderInfo` for a single backup entity, detailing its file and folder contents, total size, and creation time.
    func info(from backup: BackupEntity) async -> FolderInfo {
        guard let node = await nodeUseCase.nodeForHandle(backup.rootHandle),
              let folderInfo = try? await nodeUseCase.folderInfo(node: node) else {
            return FolderInfo.emptyFolder
        }
        
        return FolderInfo(
            files: folderInfo.files,
            folders: folderInfo.folders,
            totalSize: UInt64(folderInfo.currentSize),
            added: node.creationTime
        )
    }
    
    /// Asynchronously aggregates `FolderInfo` for an array of backup entities (specific case to obtain the folderInfo of a device), summarizing total files, folders, and size.
    func info(from backups: [BackupEntity]) async -> FolderInfo {
        var totalFiles: Int = 0
        var totalFolders: Int = 0
        var totalSize: UInt64 = 0
        
        await withTaskGroup(of: FolderInfo.self) { group in
            for backup in backups {
                group.addTask {
                    await self.info(from: backup)
                }
            }

            for await entity in group {
                totalFiles += entity.files
                totalFolders += entity.folders
                totalSize += entity.totalSize
            }
        }
        
        return FolderInfo(
            files: totalFiles,
            folders: totalFolders,
            totalSize: totalSize,
            added: nil
        )
    }
}
