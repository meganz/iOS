import Foundation

extension FileSystemRepository {
    static let `default` = FileSystemRepository(fileManager: .default)
}

struct FileSystemRepository: FileRepositoryProtocol {
    private enum Constants {
        static let thumbnailCacheDirectory = "thumbnailsV3"
        static let previewCacheDirectory = "previewsV3"
        static let originalCacheDirectory = "originalV3"
        static let groupIdentifier = "group.mega.ios"
        static let cacheDirectory = "Library/Caches/"
    }
    
    private let fileManager: FileManager
    private let appGroupSharedContrainerURL: URL
    private let appGroupSharedCacheURL: URL
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
        appGroupSharedContrainerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Constants.groupIdentifier)!
        appGroupSharedCacheURL = appGroupSharedContrainerURL.appendingPathComponent(Constants.cacheDirectory, isDirectory: true)
    }
    
    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    func systemVolumeAvailability() -> Int64 {
        let homeUrl = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try homeUrl.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return capacity
            }
        } catch {
            MEGALogError("Error retrieving volume availability: \(error.localizedDescription)")
        }
        
        return 0
    }
    
    // MARK: - Thumbnail
    func cachedThumbnailURL(for base64Handle: MEGABase64Handle) -> URL {
        let directory = appGroupSharedCacheURL.appendingPathComponent(Constants.thumbnailCacheDirectory, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(base64Handle)
    }
    
    // MARK: - Preview
    func cachedPreviewURL(for base64Handle: MEGABase64Handle) -> URL {
        let directory = appGroupSharedCacheURL.appendingPathComponent(Constants.previewCacheDirectory, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(base64Handle)
    }
    
    //MARK: - Original
    func cachedOriginalURL(for base64Handle: MEGABase64Handle, name: String) -> URL {
        let directory = appGroupSharedCacheURL.appendingPathComponent(Constants.originalCacheDirectory, isDirectory: true).appendingPathComponent(base64Handle, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(name)
    }
    
    //MARK: - Tempfolder
    func cachedFileURL(for base64Handle: MEGABase64Handle, name: String) -> URL {
        let directory = NSTemporaryDirectory().append(pathComponent: base64Handle)
        try? fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        
        return URL(fileURLWithPath: directory).appendingPathComponent(name)
    }
}
