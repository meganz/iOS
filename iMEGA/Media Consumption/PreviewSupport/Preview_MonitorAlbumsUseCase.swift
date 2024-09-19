import MEGADomain
import MEGASwift

struct Preview_MonitorUserAlbumPhotosUseCase: MonitorUserAlbumPhotosUseCaseProtocol {
    
    func monitorUserAlbumPhotos(for album: AlbumEntity, excludeSensitives: Bool,
                                includeSensitiveInherited: Bool) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
