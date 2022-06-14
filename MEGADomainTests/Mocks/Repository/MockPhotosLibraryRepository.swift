@testable import MEGA

struct MockPhotosLibraryRepository: PhotosLibraryRepositoryProtocol {
    var result: SaveMediaToPhotosErrorEntity? = nil
    
    func copyMediaFileToPhotos(at url: URL, completion: ((SaveMediaToPhotosErrorEntity?) -> Void)?) {
        completion?(result)
    }
}
