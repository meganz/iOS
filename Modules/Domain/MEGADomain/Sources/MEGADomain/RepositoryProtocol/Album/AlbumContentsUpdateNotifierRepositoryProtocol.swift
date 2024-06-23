import Combine

public protocol AlbumContentsUpdateNotifierRepositoryProtocol: RepositoryProtocol, Sendable {
    var albumReloadPublisher: AnyPublisher<Void, Never> { get }
}
