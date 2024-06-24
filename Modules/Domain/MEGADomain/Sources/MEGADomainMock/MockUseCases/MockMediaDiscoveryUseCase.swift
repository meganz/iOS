@preconcurrency import Combine
import MEGADomain

public final class MockMediaDiscoveryUseCase: MediaDiscoveryUseCaseProtocol {
    public let nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never>
    public let state = State()

    private let nodes: [NodeEntity]
    private let shouldReload: Bool
    
    public actor State {
        public var discoverRecursively: Bool?
        public var discoverWithExcludeSensitive: Bool?
        
        func update(discoverRecursively: Bool, discoverWithExcludeSensitive: Bool) {
            self.discoverRecursively = discoverRecursively
            self.discoverWithExcludeSensitive = discoverWithExcludeSensitive
        }
    }
    
    public init(
        nodeUpdates: AnyPublisher<[NodeEntity], Never> = Empty().eraseToAnyPublisher(),
        nodes: [NodeEntity] = [],
        shouldReload: Bool = true
    ) {
        self.nodeUpdatesPublisher = nodeUpdates
        self.nodes = nodes
        self.shouldReload = shouldReload
    }
    
    public func nodes(forParent parent: NodeEntity, recursive: Bool, excludeSensitive: Bool) async throws -> [NodeEntity] {
        await state.update(discoverRecursively: recursive,
                     discoverWithExcludeSensitive: excludeSensitive)
        return nodes
    }
    
    public func shouldReload(parentNode: NodeEntity, loadedNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool {
        shouldReload
    }
}
