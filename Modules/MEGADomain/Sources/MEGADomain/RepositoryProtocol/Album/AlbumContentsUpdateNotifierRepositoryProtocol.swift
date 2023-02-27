import Combine

public protocol AlbumContentsUpdateNotifierRepositoryProtocol: RepositoryProtocol {
    var albumReloadPublisher: AnyPublisher<Void, Never> { get }
}
