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
    
    public func copyMediaFileToPhotos(at url: URL) async throws(SaveMediaToPhotosErrorEntity) {
        if let error {
            throw error
        }
    }
}
