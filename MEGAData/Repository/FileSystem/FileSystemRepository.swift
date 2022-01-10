import Foundation

extension FileSystemRepository {
    static let `default` = FileSystemRepository(fileManager: .default)
}

struct FileSystemRepository: FileRepositoryProtocol {
    private enum Constants {
        static let thumbnailCacheDirectory = "thumbnailsV3"
        static let previewCacheDirectory = "previewsV3"
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
}
