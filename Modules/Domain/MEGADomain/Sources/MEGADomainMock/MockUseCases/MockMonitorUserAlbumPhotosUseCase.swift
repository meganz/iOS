import MEGADomain
import MEGASwift

public struct MockMonitorUserAlbumPhotosUseCase: MonitorUserAlbumPhotosUseCaseProtocol {
    private let monitorUserAlbumPhotosAsyncSequence: AnyAsyncSequence<[AlbumPhotoEntity]>
    public enum Invocation: Hashable, Sendable {
        case userAlbumPhotos(excludeSensitives: Bool)
    }
    @Atomic public var invocations: [Invocation] = []
    
    public init(
        monitorUserAlbumPhotosAsyncSequence: AnyAsyncSequence<[AlbumPhotoEntity]> = EmptyAsyncSequence<[AlbumPhotoEntity]>().eraseToAnyAsyncSequence()
    ) {
        self.monitorUserAlbumPhotosAsyncSequence = monitorUserAlbumPhotosAsyncSequence
    }
    
    public func monitorUserAlbumPhotos(
        for album: AlbumEntity,
        excludeSensitives: Bool
    ) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        $invocations.mutate {
            $0.append(.userAlbumPhotos(excludeSensitives: excludeSensitives))
        }
        return monitorUserAlbumPhotosAsyncSequence
    }
}
