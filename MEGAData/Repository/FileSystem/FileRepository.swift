import Foundation

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
    
    func fileTypeName(forFileExtension fileExtension: String) -> String? {
        let dict = Helper.fileTypesDictionary() as? [String: String] ?? [:]
        return dict[fileExtension.lowercased()]
    }

    func cachedThumbnailURL(forHandle base64Handle: MEGABase64Handle) -> URL {
        let directory = appGroupSharedCacheURL.appendingPathComponent(Constants.thumbnailCacheDirectory, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(base64Handle)
    }
    
    func cachedPreviewURL(forHandle base64Handle: MEGABase64Handle) -> URL {
        let directory = appGroupSharedCacheURL.appendingPathComponent(Constants.previewCacheDirectory, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(base64Handle)
    }
}
