@preconcurrency import Combine
import Foundation
import MEGADomain

public struct MockAlbumContentUseCase: AlbumContentsUseCaseProtocol {
    public actor State {
        var photos: [AlbumPhotoEntity]
        
        init(photos: [AlbumPhotoEntity]) {
            self.photos = photos
        }
        
        public func update(photos: [AlbumPhotoEntity]) {
            self.photos = photos
        }
    }
    public let state: State
    private let albumReloadPublisher: AnyPublisher<Void, Never>
    private let albumUpdatedPublisher: AnyPublisher<SetEntity, Never>?
    private let userAlbumCoverPhoto: NodeEntity?

    public init(photos: [AlbumPhotoEntity] = [],
                albumReloadPublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
                albumUpdatedPublisher: AnyPublisher<SetEntity, Never>? = nil,
                userAlbumCoverPhoto: NodeEntity? = nil) {
        state = State(photos: photos)
        self.albumReloadPublisher = albumReloadPublisher
        self.albumUpdatedPublisher = albumUpdatedPublisher
        self.userAlbumCoverPhoto = userAlbumCoverPhoto
    }
    
    public func albumReloadPublisher(forAlbum album: AlbumEntity) -> AnyPublisher<Void, Never> {
        albumReloadPublisher
    }
    
    public func photos(in album: AlbumEntity) async throws -> [AlbumPhotoEntity] {
        await state.photos
    }
    
    public func userAlbumPhotos(by id: HandleEntity, showHidden: Bool) async -> [AlbumPhotoEntity] {
        if showHidden {
            await state.photos
        } else {
            await state.photos.filter { !$0.photo.isMarkedSensitive }
        }
    }
    
    public func userAlbumUpdatedPublisher(for album: AlbumEntity) -> AnyPublisher<SetEntity, Never>? {
        albumUpdatedPublisher
    }
    
    public func userAlbumCoverPhoto(in album: AlbumEntity, forPhotoId photoId: HandleEntity) async -> NodeEntity? {
        userAlbumCoverPhoto
    }
}
