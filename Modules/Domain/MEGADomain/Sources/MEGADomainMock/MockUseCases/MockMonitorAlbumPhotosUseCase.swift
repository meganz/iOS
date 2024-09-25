import MEGADomain
import MEGASwift

public struct MockMonitorAlbumPhotosUseCase: MonitorAlbumPhotosUseCaseProtocol {
    private let monitorPhotosAsyncSequence: AnyAsyncSequence<Result<[AlbumPhotoEntity], any Error>>
    
    public init(
        monitorPhotosAsyncSequence: AnyAsyncSequence<Result<[AlbumPhotoEntity], any Error>> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.monitorPhotosAsyncSequence = monitorPhotosAsyncSequence
    }
    
    public func monitorPhotos(for album: AlbumEntity) async -> AnyAsyncSequence<Result<[AlbumPhotoEntity], any Error>> {
        monitorPhotosAsyncSequence
    }
}
