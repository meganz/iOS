import Combine
import MEGADomain

public final class MockMediaDiscoveryRepository: MediaDiscoveryRepositoryProtocol {
    public static let newRepo = MockMediaDiscoveryRepository()
    
    public var nodesUpdatePublisher: AnyPublisher<[NodeEntity], Never>
    private let nodes: [NodeEntity]
    
    public var startMonitoringNodesUpdateCalled = 0
    public var stopMonitoringNodesUpdateCalled = 0
    
    public init(nodesUpdatePublisher: AnyPublisher<[NodeEntity], Never> = Empty().eraseToAnyPublisher(),
                nodes: [NodeEntity] = []) {
        self.nodesUpdatePublisher = nodesUpdatePublisher
        self.nodes = nodes
    }
    
    public func loadNodes(forParent parent: NodeEntity) async throws -> [NodeEntity] {
        nodes
    }
    
    public func startMonitoringNodesUpdate() {
        startMonitoringNodesUpdateCalled += 1
    }
    
    public func stopMonitoringNodesUpdate() {
        stopMonitoringNodesUpdateCalled += 1
    }
}
