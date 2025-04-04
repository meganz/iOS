import MEGADomain
import MEGASwift

public struct MockMonitorAlbumsUseCase: MonitorAlbumsUseCaseProtocol {
    public actor State {
        public enum MonitorType: Hashable, Sendable {
            case systemAlbum(excludeSensitives: Bool)
            case userAlbum(excludeSensitives: Bool)
        }
        public var monitorTypes = [MonitorType]()
        
        func insertMonitorType(_ newValue: MonitorType) {
            monitorTypes.append(newValue)
        }
    }
    public let state = State()
    private let monitorSystemAlbumsSequence: AnyAsyncSequence<Result<[AlbumEntity], any Error>>
    private let monitorUserAlbumsSequence: AnyAsyncSequence<[AlbumEntity]>
    
    public init(
        monitorSystemAlbumsSequence: AnyAsyncSequence<Result<[AlbumEntity], any Error>> = EmptyAsyncSequence<Result<[AlbumEntity], any Error>>().eraseToAnyAsyncSequence(),
        monitorUserAlbumsSequence: AnyAsyncSequence<[AlbumEntity]> = EmptyAsyncSequence<[AlbumEntity]>().eraseToAnyAsyncSequence()
    ) {
        self.monitorSystemAlbumsSequence = monitorSystemAlbumsSequence
        self.monitorUserAlbumsSequence = monitorUserAlbumsSequence
    }
    
    public func monitorSystemAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<Result<[AlbumEntity], any Error>> {
        await state.insertMonitorType(.systemAlbum(excludeSensitives: excludeSensitives))
        return monitorSystemAlbumsSequence
    }
    
    public func monitorUserAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<[AlbumEntity]> {
        await state.insertMonitorType(.userAlbum(excludeSensitives: excludeSensitives))
        return monitorUserAlbumsSequence
    }
}
