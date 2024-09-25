import MEGADomain
import MEGASwift

public struct MockMonitorSystemAlbumPhotosUseCase: MonitorSystemAlbumPhotosUseCaseProtocol {
    private let monitorPhotosAsyncSequence: AnyAsyncSequence<Result<[NodeEntity], any Error>>
    
    public enum Invocation: Hashable, Sendable {
        case monitorPhotos(albumType: AlbumEntityType, excludeSensitive: Bool)
    }
    @Atomic public var invocations: [Invocation] = []
    
    public init(
        monitorPhotosAsyncSequence: AnyAsyncSequence<Result<[NodeEntity], any Error>> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.monitorPhotosAsyncSequence = monitorPhotosAsyncSequence
    }
    
    public func monitorPhotos(for albumType: AlbumEntityType, excludeSensitive: Bool) async -> AnyAsyncSequence<Result<[NodeEntity], any Error>> {
        $invocations.mutate {
            $0.append(.monitorPhotos(albumType: albumType,
                                     excludeSensitive: excludeSensitive))
        }
        return monitorPhotosAsyncSequence
    }
}
