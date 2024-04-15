import MEGADomain
import MEGASwift

struct Preview_MonitorAlbumsUseCase: MonitorAlbumsUseCaseProtocol {
    func monitorSystemAlbums() async -> AnyAsyncSequence<Result<[AlbumEntity], any Error>> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    func monitorUserAlbums() async -> AnyAsyncSequence<[AlbumEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    func monitorUserAlbumPhotos(for album: AlbumEntity) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
