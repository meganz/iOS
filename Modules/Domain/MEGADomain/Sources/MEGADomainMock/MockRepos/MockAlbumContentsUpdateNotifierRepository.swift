import Combine
import MEGADomain

public final class MockAlbumContentsUpdateNotifierRepository: AlbumContentsUpdateNotifierRepositoryProtocol {
    public static var newRepo: MockAlbumContentsUpdateNotifierRepository {
        MockAlbumContentsUpdateNotifierRepository()
    }
    
    public var albumReloadPublisher: AnyPublisher<Void, Never>
    
    public init(albumReloadPublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()) {
        self.albumReloadPublisher = albumReloadPublisher
    }
}
