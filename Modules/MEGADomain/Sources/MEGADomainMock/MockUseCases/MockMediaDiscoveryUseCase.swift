import Combine
import MEGADomain

public struct MockMediaDiscoveryUseCase: MediaDiscoveryUseCaseProtocol {
    public let nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never>
    private let nodes: [NodeEntity]
    private let shouldReload: Bool
    
    public init(nodeUpdates: AnyPublisher<[NodeEntity], Never> = Empty().eraseToAnyPublisher(),
         nodes: [NodeEntity] = [], shouldReload: Bool = true) {
        self.nodeUpdatesPublisher = nodeUpdates
        self.nodes = nodes
        self.shouldReload = shouldReload
    }
    
    public func nodes(forParent parent: NodeEntity) async throws -> [NodeEntity] {
        nodes
    }
    
    public func shouldReload(parentNode: NodeEntity, loadedNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool {
        shouldReload
    }
}
