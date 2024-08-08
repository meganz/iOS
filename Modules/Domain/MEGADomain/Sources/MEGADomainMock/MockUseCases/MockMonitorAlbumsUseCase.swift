import MEGADomain
import MEGASwift

public struct MockMonitorAlbumsUseCase: MonitorAlbumsUseCaseProtocol {
    public actor State {
        public enum MonitorType: Hashable, Sendable {
            case systemAlbum(excludeSensitives: Bool)
            case userAlbum(excludeSensitives: Bool)
            case userAlbumPhotos(excludeSensitives: Bool, includeSensitiveInherited: Bool)
        }
        public var monitorTypes = [MonitorType]()
        
        func insertMonitorType(_ newValue: MonitorType) {
            monitorTypes.append(newValue)
        }
    }
    public let state = State()
    private let monitorSystemAlbumsSequence: AnyAsyncSequence<Result<[AlbumEntity], Error>>
    private let monitorUserAlbumsSequence: AnyAsyncSequence<[AlbumEntity]>
    private let monitorUserAlbumPhotosAsyncSequence: AnyAsyncSequence<[AlbumPhotoEntity]>
    
    public init(
        monitorSystemAlbumsSequence: AnyAsyncSequence<Result<[AlbumEntity], Error>> = EmptyAsyncSequence<Result<[AlbumEntity], Error>>().eraseToAnyAsyncSequence(),
        monitorUserAlbumsSequence: AnyAsyncSequence<[AlbumEntity]> = EmptyAsyncSequence<[AlbumEntity]>().eraseToAnyAsyncSequence(),
        monitorUserAlbumPhotosAsyncSequence: AnyAsyncSequence<[AlbumPhotoEntity]> = EmptyAsyncSequence<[AlbumPhotoEntity]>().eraseToAnyAsyncSequence()
    ) {
        self.monitorSystemAlbumsSequence = monitorSystemAlbumsSequence
        self.monitorUserAlbumsSequence = monitorUserAlbumsSequence
        self.monitorUserAlbumPhotosAsyncSequence = monitorUserAlbumPhotosAsyncSequence
    }
    
    public func monitorSystemAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<Result<[AlbumEntity], Error>> {
        await state.insertMonitorType(.systemAlbum(excludeSensitives: excludeSensitives))
        return monitorSystemAlbumsSequence
    }
    
    public func monitorUserAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<[AlbumEntity]> {
        await state.insertMonitorType(.userAlbum(excludeSensitives: excludeSensitives))
        return monitorUserAlbumsSequence
    }
    
    public func monitorUserAlbumPhotos(for album: AlbumEntity,
                                       excludeSensitives: Bool,
                                       includeSensitiveInherited: Bool) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        await state.insertMonitorType(.userAlbumPhotos(
            excludeSensitives: excludeSensitives, includeSensitiveInherited: includeSensitiveInherited))
        return monitorUserAlbumPhotosAsyncSequence
    }
}
