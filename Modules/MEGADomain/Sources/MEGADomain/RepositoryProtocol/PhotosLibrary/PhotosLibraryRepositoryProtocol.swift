import Foundation

public protocol PhotosLibraryRepositoryProtocol: RepositoryProtocol {
    func copyMediaFileToPhotos(at url: URL, completion: ((SaveMediaToPhotosErrorEntity?) -> Void)?)
}
