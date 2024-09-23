import MEGADomain
import MEGASwift

public struct MockMonitorUserAlbumPhotosUseCase: MonitorUserAlbumPhotosUseCaseProtocol {
    public actor State {
        public enum Invocation: Hashable, Sendable {
            case userAlbumPhotos(excludeSensitives: Bool)
        }
        public var invocations = [Invocation]()
        
        func addInvocation(_ newValue: Invocation) {
            invocations.append(newValue)
        }
    }
    public let state = State()
    private let monitorUserAlbumPhotosAsyncSequence: AnyAsyncSequence<[AlbumPhotoEntity]>
    
    public init(
        monitorUserAlbumPhotosAsyncSequence: AnyAsyncSequence<[AlbumPhotoEntity]> = EmptyAsyncSequence<[AlbumPhotoEntity]>().eraseToAnyAsyncSequence()
    ) {
        self.monitorUserAlbumPhotosAsyncSequence = monitorUserAlbumPhotosAsyncSequence
    }
    
    public func monitorUserAlbumPhotos(
        for album: AlbumEntity,
        excludeSensitives: Bool
    ) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        await state.addInvocation(.userAlbumPhotos(excludeSensitives: excludeSensitives))
        return monitorUserAlbumPhotosAsyncSequence
    }
}
