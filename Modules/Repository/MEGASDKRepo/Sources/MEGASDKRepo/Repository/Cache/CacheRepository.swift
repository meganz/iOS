import Foundation
import MEGADomain
import MEGAFoundation
import MEGASdk

public struct GroupSharedDirectory {
    public static let identifier = "group.mega.ios"
    public static let extensionLogsFolder = "logs"
    public static let fileExtensionStorageFolder = "File Provider Storage"
    public static let shareExtensionStorageFolder = "Share Extension Storage"
    public static let megaExtension = "mega"
}

public struct CacheRepository: CacheRepositoryProtocol {
    public static var newRepo: CacheRepository {
        CacheRepository(
            directoryProvider: DirectoryProvider(),
            folderSizeCalculator: FolderSizeCalculator(),
            directoryCleaner: DirectoryCleaner(),
            sdk: MEGASdk.sharedSdk
        )
    }
    
    private let directoryProvider: any DirectoryProvidingProtocol
    private let folderSizeCalculator: any FolderSizeCalculatingProtocol
    private let directoryCleaner: any DirectoryCleaningProtocol
    private let sdk: MEGASdk
    
    public init(
        directoryProvider: some DirectoryProvidingProtocol,
        folderSizeCalculator: some FolderSizeCalculatingProtocol,
        directoryCleaner: some DirectoryCleaningProtocol,
        sdk: MEGASdk
    ) {
        self.directoryProvider = directoryProvider
        self.folderSizeCalculator = folderSizeCalculator
        self.directoryCleaner = directoryCleaner
        self.sdk = sdk
    }
    
    public func cacheSize() throws -> UInt64 {
        let cacheFolderSize = folderSizeCalculator.folderSize(
            at: try directoryProvider.urlForSharedSandboxCacheDirectory("")
        )
        
        let tempURL = try directoryProvider.urlForSharedSandboxCacheDirectory(NSTemporaryDirectory())
        let temporaryDirectorySize = folderSizeCalculator.folderSize(at: tempURL)
        
        let groupDirectorySize = folderSizeCalculator.groupSharedDirectorySize(
            groupIdentifier: GroupSharedDirectory.identifier
        )
        
        return cacheFolderSize + temporaryDirectorySize + groupDirectorySize
    }
    
    public func cleanCache() async throws {
        try await Task(priority: .utility) {
            guard try cacheSize() > 0 else { return }
            
            if let tempDirectoryURL = URL(string: NSTemporaryDirectory()) {
                try directoryCleaner.removeFolderContents(at: tempDirectoryURL)
            }
            
            let sandboxCacheDir = try directoryProvider.urlForSharedSandboxCacheDirectory("")
            try directoryCleaner.removeFolderContents(at: sandboxCacheDir)
            
            try removeGroupSharedDirectoryContents()
            
            if sdk.downloadTransfers.size == 0 {
                if let offlineURL = directoryProvider.pathForOffline() {
                    try directoryCleaner.removeFolderContentsRecursively(
                        at: offlineURL,
                        withExtension: GroupSharedDirectory.megaExtension
                    )
                }
                let downloadsDirectory = try directoryProvider.downloadsDirectory()
                try directoryCleaner.removeItemAtURL(downloadsDirectory)
            }
            
            if sdk.uploadTransfers.size == 0 {
                let uploadsDirectory = try directoryProvider.uploadsDirectory()
                try directoryCleaner.removeItemAtURL(uploadsDirectory)
            }
        }.value
    }
    
    // MARK: - Helpers
    private func removeGroupSharedDirectoryContents() throws {
        guard let groupSharedURL = directoryProvider.groupSharedURL() else {
            return
        }
        
        try directoryCleaner.removeFolderContents(
            at: groupSharedURL.appendingPathComponent(GroupSharedDirectory.extensionLogsFolder)
        )
        try directoryCleaner.removeFolderContents(
            at: groupSharedURL.appendingPathComponent(GroupSharedDirectory.fileExtensionStorageFolder)
        )
        try directoryCleaner.removeFolderContents(
            at: groupSharedURL.appendingPathComponent(GroupSharedDirectory.shareExtensionStorageFolder)
        )
    }
}
