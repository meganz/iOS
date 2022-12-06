import Combine

public protocol MediaDiscoveryRepositoryProtocol: RepositoryProtocol {
    var nodesUpdatePublisher: AnyPublisher<[NodeEntity], Never> { get }
    func loadNodes(forParent parent: NodeEntity) async throws -> [NodeEntity]
    func startMonitoringNodesUpdate()
    func stopMonitoringNodesUpdate()
}
