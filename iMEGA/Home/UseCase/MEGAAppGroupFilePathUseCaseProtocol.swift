import Foundation

protocol MEGAAppGroupFilePathUseCaseProtocol {
    
    var groupSharedContrainerURL: URL { get }
    
    var groupCacheDirectoryURL: URL { get }

    var nodeThumbnailCacheDirectoryURL: URL { get }

    func cachedThumbnailImageURL(forNode base64Handle: MEGABase64Handle) -> URL
}

struct MEGAAppGroupFilePathUseCase: MEGAAppGroupFilePathUseCaseProtocol {

    private enum Constant {
        static let thumbnailCacheFolderName = "thumbnailsV3"
    }
    
    private var fileManager: FileManager
    
    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }
    
    var groupSharedContrainerURL: URL {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier)!
    }
    
    var groupCacheDirectoryURL: URL {
        groupSharedContrainerURL.appendingPathComponent(MEGAExtensionCacheFolder, isDirectory: true)
    }

    var nodeThumbnailCacheDirectoryURL: URL {
        groupCacheDirectoryURL.appendingPathComponent(Constant.thumbnailCacheFolderName, isDirectory: true)
    }

    func cachedThumbnailImageURL(forNode base64Handle: MEGABase64Handle) -> URL {
        nodeThumbnailCacheDirectoryURL.appendingPathComponent(base64Handle)
    }
}
