import Foundation
import MEGADomain

final class FileCacheRepository: FileCacheRepositoryProtocol {
    static var newRepo: FileCacheRepository {
        FileCacheRepository(fileManager: .default)
    }
    
    private enum Constants {
        static let originalCacheDirectory = "originalV3"
        static let uploadsDirectory = "Uploads"
    }
    
    private let fileManager: FileManager
    private lazy var appGroup: AppGroupContainer = AppGroupContainer(fileManager: fileManager)
    
    var tempFolder: URL {
        fileManager.temporaryDirectory
    }

    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    // MARK: - Temp file cache
    func tempFileURL(for node: NodeEntity) -> URL {
        base64HandleTempFolder(for: node.base64Handle).appendingPathComponent(node.name)
    }
    
    func base64HandleTempFolder(for base64Handle: Base64HandleEntity) -> URL {
        let directoryURL = tempFolder.appendingPathComponent(base64Handle)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        return directoryURL
    }
    
    func existingTempFileURL(for node: NodeEntity) -> URL? {
        let url = tempFileURL(for: node)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
    
    // MARK: - Original image cache
    private(set) lazy var cachedOriginalImageDirectoryURL = appGroup.url(for: .cache)
        .appendingPathComponent(Constants.originalCacheDirectory, isDirectory: true)
    
    func cachedOriginalImageURL(for node: NodeEntity) -> URL {
        let directory = cachedOriginalImageDirectoryURL
            .appendingPathComponent(node.base64Handle, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(node.name)
    }
    
    func existingOriginalImageURL(for node: NodeEntity) -> URL? {
        let url = cachedOriginalImageURL(for: node)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
    
    func cachedOriginalURL(for base64Handle: Base64HandleEntity, name: String) -> URL {
        let directory = cachedOriginalImageDirectoryURL.appendingPathComponent(base64Handle, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(name)
    }
    
    // MARK: - Uploads
    func tempUploadURL(for name: String) -> URL {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent(Constants.uploadsDirectory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(name)
    }
    
    // MARK: - Offline
    func offlineFileURL(name: String) -> URL {
        (fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "")).appendingPathComponent(name)
    }
}
