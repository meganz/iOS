import Combine

public protocol AudioPlayerRepositoryProtocol: RepositoryProtocol, Sendable {
    var reloadItemPublisher: AnyPublisher<[NodeEntity], Never> { get }
    
    func registerMEGADelegate() async
    func unregisterMEGADelegate() async
}
