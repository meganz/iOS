import MEGADomain
import MEGASwift

struct Preview_MonitorAlbumsUseCase: MonitorAlbumsUseCaseProtocol {
    func monitorSystemAlbums() async throws -> AnyAsyncSequence<[AlbumEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    func monitorUserAlbums() async throws -> AnyAsyncSequence<[AlbumEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    func monitorUserAlbumPhotos(for album: AlbumEntity) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
