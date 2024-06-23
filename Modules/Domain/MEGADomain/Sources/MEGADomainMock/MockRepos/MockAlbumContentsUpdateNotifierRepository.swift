@preconcurrency import Combine
import MEGADomain

public final class MockAlbumContentsUpdateNotifierRepository: AlbumContentsUpdateNotifierRepositoryProtocol {
    public static var newRepo: MockAlbumContentsUpdateNotifierRepository {
        MockAlbumContentsUpdateNotifierRepository()
    }
    
    public let albumReloadPublisher: AnyPublisher<Void, Never>
    
    public init(albumReloadPublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()) {
        self.albumReloadPublisher = albumReloadPublisher
    }
}
