import MEGADomain
import MEGASwift

public struct MockMonitorAlbumsUseCase: MonitorAlbumsUseCaseProtocol {
    private let monitorSystemAlbumsResult: Result<AnyAsyncSequence<[AlbumEntity]>, any Error>
    private let monitorUserAlbumsResult: Result<AnyAsyncSequence<[AlbumEntity]>, any Error>
    private let monitorUserAlbumPhotosAsyncSequence: AnyAsyncSequence<[AlbumPhotoEntity]>
    
    public init(
        monitorSystemAlbumsResult: Result<AnyAsyncSequence<[AlbumEntity]>, any Error> = .failure(GenericErrorEntity()),
        monitorUserAlbumsResult: Result<AnyAsyncSequence<[AlbumEntity]>, any Error> = .failure(GenericErrorEntity()),
        monitorUserAlbumPhotosAsyncSequence: AnyAsyncSequence<[AlbumPhotoEntity]> = EmptyAsyncSequence<[AlbumPhotoEntity]>().eraseToAnyAsyncSequence()
    ) {
        self.monitorSystemAlbumsResult = monitorSystemAlbumsResult
        self.monitorUserAlbumsResult = monitorUserAlbumsResult
        self.monitorUserAlbumPhotosAsyncSequence = monitorUserAlbumPhotosAsyncSequence
    }
    
    public func monitorSystemAlbums() async throws -> AnyAsyncSequence<[AlbumEntity]> {
        try await withCheckedThrowingContinuation {
            $0.resume(with: monitorSystemAlbumsResult)
        }
    }
    
    public func monitorUserAlbums() async throws -> AnyAsyncSequence<[AlbumEntity]> {
        try await withCheckedThrowingContinuation {
            $0.resume(with: monitorUserAlbumsResult)
        }
    }
    
    public func monitorUserAlbumPhotos(for album: AlbumEntity) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        monitorUserAlbumPhotosAsyncSequence
    }
}
