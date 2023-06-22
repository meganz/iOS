import Combine
import Foundation
import MEGADomain

public struct MockAlbumContentUseCase: AlbumContentsUseCaseProtocol {
    public var photos: [AlbumPhotoEntity]
    private let albumReloadPublisher: AnyPublisher<Void, Never>
    private let albumUpdatedPublisher: AnyPublisher<SetEntity, Never>?
    private let userAlbumCoverPhoto: NodeEntity?

    public init(photos: [AlbumPhotoEntity] = [],
                albumReloadPublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
                albumUpdatedPublisher: AnyPublisher<SetEntity, Never>? = nil,
                userAlbumCoverPhoto: NodeEntity? = nil) {
        self.photos = photos
        self.albumReloadPublisher = albumReloadPublisher
        self.albumUpdatedPublisher = albumUpdatedPublisher
        self.userAlbumCoverPhoto = userAlbumCoverPhoto
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
    
    public func userAlbumUpdatedPublisher(for album: AlbumEntity) -> AnyPublisher<SetEntity, Never>? {
        albumUpdatedPublisher
    }
    
    public func userAlbumCoverPhoto(in album: AlbumEntity, forPhotoId photoId: HandleEntity) async -> NodeEntity? {
        userAlbumCoverPhoto
    }
}
