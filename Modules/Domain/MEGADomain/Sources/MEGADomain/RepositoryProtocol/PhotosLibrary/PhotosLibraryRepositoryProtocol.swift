import Foundation

public protocol PhotosLibraryRepositoryProtocol: RepositoryProtocol, Sendable {
    func copyMediaFileToPhotos(at url: URL) async throws(SaveMediaToPhotosErrorEntity)
}
