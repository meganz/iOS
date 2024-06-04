import MEGADomain
import MEGASwift

public struct MockMonitorAlbumsUseCase: MonitorAlbumsUseCaseProtocol {
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
        monitorSystemAlbumsSequence
    }
    
    public func monitorUserAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<[AlbumEntity]> {
        monitorUserAlbumsSequence
    }
    
    public func monitorUserAlbumPhotos(for album: AlbumEntity, excludeSensitives: Bool,
                                       includeSensitiveInherited: Bool) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        monitorUserAlbumPhotosAsyncSequence
    }
}
