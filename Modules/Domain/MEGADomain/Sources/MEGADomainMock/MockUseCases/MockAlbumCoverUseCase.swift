import MEGADomain

public struct MockAlbumCoverUseCase: AlbumCoverUseCaseProtocol {
    private let albumCover: NodeEntity?
    
    public init(albumCover: NodeEntity? = nil) {
        self.albumCover = albumCover
    }
    
    public func albumCover(for album: AlbumEntity, photos: [AlbumPhotoEntity]) async -> NodeEntity? {
        albumCover
    }
}
