import MEGADomain
import MEGASwift

struct Preview_MonitorAlbumsUseCase: MonitorAlbumsUseCaseProtocol {
    func monitorSystemAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<Result<[AlbumEntity], any Error>> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    func monitorUserAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<[AlbumEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    func monitorUserAlbumPhotos(for album: AlbumEntity, excludeSensitives: Bool,
                                includeSensitiveInherited: Bool) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
