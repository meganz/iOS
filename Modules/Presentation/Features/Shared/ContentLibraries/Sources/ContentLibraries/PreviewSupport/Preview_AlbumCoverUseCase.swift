import MEGADomain

struct Preview_AlbumCoverUseCase: AlbumCoverUseCaseProtocol {
    func albumCover(for album: AlbumEntity, photos: [AlbumPhotoEntity]) async -> NodeEntity? {
        nil
    }
}
