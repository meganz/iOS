import Foundation
import MEGADomain
import MEGASdk

public final class FileCacheRepository: FileCacheRepositoryProtocol {
    public static var newRepo: FileCacheRepository {
        FileCacheRepository(fileManager: .default)
    }

    private enum Constants {
        static let originalCacheDirectory = "originalV3"
        static let uploadsDirectory = "Uploads"
        /// Appended to the containing folder rather than to the node's own name, so that a staged copy
        /// keeps the name the user knows it by.
        static let stagingDirectorySuffix = ".incomplete"
        static let exportDirectory = "ExportFile"
    }
    
    private let fileManager: FileManager
    private let appGroup: AppGroupContainer
    /// Only used to turn a node name into the name it has on disk; see `MEGASdk.fileSystemName(for:destinationPath:)`.
    private let sdk: MEGASdk

    public var tempFolder: URL {
        fileManager.temporaryDirectory
    }

    public var exportFolder: URL {
        let directoryURL = tempFolder.appendingPathComponent(Constants.exportDirectory, isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        return directoryURL
    }

    public func tempExportFolder(name: String) -> URL {
        let directoryURL = exportFolder.appendingPathComponent(name, isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        return directoryURL
    }

    public let tempUploadURL: URL

    public init(fileManager: FileManager, sdk: MEGASdk = .sharedSdk) {
        self.fileManager = fileManager
        self.sdk = sdk
        self.appGroup = AppGroupContainer(fileManager: fileManager)
        self.cachedOriginalImageDirectoryURL = appGroup.url(for: .cache)
            .appendingPathComponent(Constants.originalCacheDirectory, isDirectory: true)

        let uploadDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: Constants.uploadsDirectory)
        try? fileManager.createDirectory(at: uploadDirectory, withIntermediateDirectories: true)
        self.tempUploadURL = uploadDirectory
    }
    
    // MARK: - Temp file cache
    public func tempFileURL(for node: NodeEntity) -> URL {
        base64HandleTempFolder(for: node.base64Handle).appendingFileSystemName(for: node.name, sdk: sdk)
    }

    public func stagingTempFileURL(for node: NodeEntity) -> URL {
        stagingTempFolder(for: node).appendingFileSystemName(for: node.name, sdk: sdk)
    }

    public func stagingTempFolder(for node: NodeEntity) -> URL {
        base64HandleTempFolder(for: node.base64Handle + Constants.stagingDirectorySuffix)
    }

    public func base64HandleTempFolder(for base64Handle: Base64HandleEntity) -> URL {
        let directoryURL = tempFolder.appendingPathComponent(base64Handle)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        return directoryURL
    }
    
    public func existingTempFileURL(for node: NodeEntity) -> URL? {
        let url = tempFileURL(for: node)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
    
    // MARK: - Original image cache
    public let cachedOriginalImageDirectoryURL: URL
    
    public func cachedOriginalImageURL(for node: NodeEntity) -> URL {
        let directory = cachedOriginalImageDirectoryURL
            .appendingPathComponent(node.base64Handle, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingFileSystemName(for: node.name, sdk: sdk)
    }
    
    public func existingOriginalImageURL(for node: NodeEntity) -> URL? {
        let url = cachedOriginalImageURL(for: node)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
    
    public func cachedOriginalURL(for base64Handle: Base64HandleEntity, name: String) -> URL {
        let directory = cachedOriginalImageDirectoryURL.appendingPathComponent(base64Handle, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingFileSystemName(for: name, sdk: sdk)
    }
    
    // MARK: - Uploads
    public func tempUploadURL(for name: String) -> URL {
        tempUploadURL.appendingPathComponent(name)
    }
    
    // MARK: - Offline
    public func offlineFileURL(name: String) -> URL {
        (fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "")).appendingPathComponent(name)
    }
}

private extension URL {
    /// Appends a node name as the single path component it has on disk, so that a name holding `/` or
    /// equal to `..` cannot leave this directory.
    func appendingFileSystemName(for nodeName: String, sdk: MEGASdk) -> URL {
        appendingPathComponent(sdk.fileSystemName(for: nodeName, destinationPath: path))
    }
}
