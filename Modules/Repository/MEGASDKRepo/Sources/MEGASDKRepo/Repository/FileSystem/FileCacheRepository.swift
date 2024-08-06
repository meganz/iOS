import Foundation
import MEGADomain

public final class FileCacheRepository: FileCacheRepositoryProtocol {
    public static var newRepo: FileCacheRepository {
        FileCacheRepository(fileManager: .default)
    }

    private enum Constants {
        static let originalCacheDirectory = "originalV3"
        static let uploadsDirectory = "Uploads"
    }
    
    private let fileManager: FileManager
    private let appGroup: AppGroupContainer

    public var tempFolder: URL {
        fileManager.temporaryDirectory
    }

    public init(fileManager: FileManager) {
        self.fileManager = fileManager
        self.appGroup =  AppGroupContainer(fileManager: fileManager)
        self.cachedOriginalImageDirectoryURL = appGroup.url(for: .cache)
            .appendingPathComponent(Constants.originalCacheDirectory, isDirectory: true)
    }
    
    // MARK: - Temp file cache
    public func tempFileURL(for node: NodeEntity) -> URL {
        base64HandleTempFolder(for: node.base64Handle).appendingPathComponent(node.name)
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
        return directory.appendingPathComponent(node.name)
    }
    
    public func existingOriginalImageURL(for node: NodeEntity) -> URL? {
        let url = cachedOriginalImageURL(for: node)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
    
    public func cachedOriginalURL(for base64Handle: Base64HandleEntity, name: String) -> URL {
        let directory = cachedOriginalImageDirectoryURL.appendingPathComponent(base64Handle, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(name)
    }
    
    // MARK: - Uploads
    public func tempUploadURL(for name: String) -> URL {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent(Constants.uploadsDirectory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(name)
    }
    
    // MARK: - Offline
    public func offlineFileURL(name: String) -> URL {
        (fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "")).appendingPathComponent(name)
    }
}
