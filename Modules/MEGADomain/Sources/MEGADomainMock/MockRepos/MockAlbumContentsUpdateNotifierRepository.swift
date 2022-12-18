import MEGADomain

public final class MockAlbumContentsUpdateNotifierRepository: AlbumContentsUpdateNotifierRepositoryProtocol {
    public var onAlbumReload: (() -> Void)?
    
    public init() {}
}
