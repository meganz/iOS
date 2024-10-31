import MEGADomain
import MEGASwift

struct Preview_MonitorUserAlbumPhotosUseCase: MonitorUserAlbumPhotosUseCaseProtocol {
    
    func monitorUserAlbumPhotos(
        for album: AlbumEntity,
        excludeSensitives: Bool
    ) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
