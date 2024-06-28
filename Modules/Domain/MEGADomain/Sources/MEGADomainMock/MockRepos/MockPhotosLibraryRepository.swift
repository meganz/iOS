import Foundation
import MEGADomain

public struct MockPhotosLibraryRepository: PhotosLibraryRepositoryProtocol {
    public static var newRepo: MockPhotosLibraryRepository {
        MockPhotosLibraryRepository()
    }
    
    private let error: SaveMediaToPhotosErrorEntity?

    public init(error: SaveMediaToPhotosErrorEntity? = nil) {
        self.error = error
    }
    
    public func copyMediaFileToPhotos(at url: URL, completion: ((SaveMediaToPhotosErrorEntity?) -> Void)?) {
        completion?(error)
    }
}
