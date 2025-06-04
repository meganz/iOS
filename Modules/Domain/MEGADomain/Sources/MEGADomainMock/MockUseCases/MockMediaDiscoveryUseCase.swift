import MEGADomain
import MEGASwift

public final class MockMediaDiscoveryUseCase: MediaDiscoveryUseCaseProtocol {
    public let nodeUpdates: AnyAsyncSequence<[NodeEntity]>
    
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
        nodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        nodes: [NodeEntity] = [],
        shouldReload: Bool = true
    ) {
        self.nodeUpdates = nodeUpdates
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
