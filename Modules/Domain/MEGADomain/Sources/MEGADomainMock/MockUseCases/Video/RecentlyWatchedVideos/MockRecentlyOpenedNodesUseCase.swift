import MEGADomain
import MEGASwift

public final class MockRecentlyOpenedNodesUseCase: RecentlyOpenedNodesUseCaseProtocol, @unchecked Sendable {
    
    public enum Invocation: Sendable, Equatable {
        case loadNodes
        case clearNodes
        case saveNode
        case clearNode
    }
    
    @Atomic public var invocations = [Invocation]()
    
    private let loadNodesResult: Result<[RecentlyOpenedNodeEntity], any Error>
    
    public init(
        loadNodesResult: Result<[RecentlyOpenedNodeEntity], any Error> = .failure(GenericErrorEntity())
    ) {
        self.loadNodesResult = loadNodesResult
    }
    
    public func loadNodes() async throws -> [RecentlyOpenedNodeEntity] {
        $invocations.mutate { $0.append(.loadNodes) }
        return try loadNodesResult.get()
    }
    
    public func clearNodes() throws {
        $invocations.mutate { $0.append(.clearNodes) }
    }
    
    public func saveNode(recentlyOpenedNode: RecentlyOpenedNodeEntity) throws {
        $invocations.mutate { $0.append(.saveNode) }
        throw GenericErrorEntity()
    }
    
    public func clearNode(for fingerprint: String) async throws {
        $invocations.mutate { $0.append(.clearNode) }
    }
}
