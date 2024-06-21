import Combine

public protocol AudioPlayerRepositoryProtocol: RepositoryProtocol {
    var reloadItemPublisher: AnyPublisher<[NodeEntity], Never> { get }
    
    func registerMEGADelegate() async
    func unregisterMEGADelegate() async
}
