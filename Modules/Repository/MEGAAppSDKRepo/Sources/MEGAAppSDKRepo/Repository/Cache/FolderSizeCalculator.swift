import Foundation

public protocol FolderSizeCalculatingProtocol: Sendable {
    func folderSize(at url: URL) -> UInt64
    func groupSharedDirectorySize(groupIdentifier: String) -> UInt64
}

public struct FolderSizeCalculator: FolderSizeCalculatingProtocol {
    private let fileManager: FileManager
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    public func folderSize(at url: URL) -> UInt64 {
        var totalSize: UInt64 = 0
        guard let directoryContents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: []
        ) else {
            return 0
        }

        for fileURL in directoryContents {
            let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            let isDirectory = resourceValues?.isDirectory == true
            if isDirectory {
                totalSize += folderSize(at: fileURL)
            } else {
                let fileSize = resourceValues?.fileSize ?? 0
                totalSize += UInt64(fileSize)
            }
        }
        return totalSize
    }
    
    public func groupSharedDirectorySize(groupIdentifier: String) -> UInt64 {
        guard let groupSharedURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        ) else {
            return 0
        }
        
        let logsSize = folderSize(
            at: groupSharedURL.appendingPathComponent(GroupSharedDirectory.extensionLogsFolder)
        )
        let fileProviderSize = folderSize(
            at: groupSharedURL.appendingPathComponent(GroupSharedDirectory.fileExtensionStorageFolder)
        )
        let shareExtensionSize = folderSize(
            at: groupSharedURL.appendingPathComponent(GroupSharedDirectory.shareExtensionStorageFolder)
        )
        
        return logsSize + fileProviderSize + shareExtensionSize
    }
}
