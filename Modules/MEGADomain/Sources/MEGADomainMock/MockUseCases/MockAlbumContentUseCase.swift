import Foundation
import MEGADomain
import Combine

public struct MockAlbumContentUseCase: AlbumContentsUseCaseProtocol {
    private let photos: [AlbumPhotoEntity]
    private let albumReloadPublisher: AnyPublisher<Void, Never>

    public init(photos: [AlbumPhotoEntity] = [],
                albumReloadPublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()) {
        self.photos = photos
        self.albumReloadPublisher = albumReloadPublisher
    }
    
    public func albumReloadPublisher(forAlbum album: AlbumEntity) -> AnyPublisher<Void, Never> {
        albumReloadPublisher
    }
    
    public func photos(in album: AlbumEntity) async throws -> [AlbumPhotoEntity] {
        photos
    }
    
    public func userAlbumPhotos(by id: HandleEntity) async -> [AlbumPhotoEntity] {
        photos
    }
}
