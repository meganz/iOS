import MEGADomain

public final class MockRecentlyOpenedNodesRepository: RecentlyOpenedNodesRepositoryProtocol, @unchecked Sendable {
    
    public enum Message: Equatable {
        case loadNodes
        case clearNodes
        case saveNode(RecentlyOpenedNodeEntity)
        case clearNode
    }
    
    public private(set) var messages: [Message] = []
    
    private let loadNodesResult: Result<[RecentlyOpenedNodeEntity], any Error>
    private let clearNodesResult: Result<Void, any Error>
    private let saveNodeResult: Result<Void, any Error>
    private let clearNodeResult: Result<Void, RecentlyOpenedNodesErrorEntity>
    
    public init(
        loadNodesResult: Result<[RecentlyOpenedNodeEntity], any Error> = .failure(GenericErrorEntity()),
        clearNodesResult: Result<Void, any Error> = .failure(GenericErrorEntity()),
        saveNodeResult: Result<Void, any Error> = .failure(GenericErrorEntity()),
        clearNodeResult: Result<Void, RecentlyOpenedNodesErrorEntity> = .failure(.couldNotFindNodeForFingerprint)
    ) {
        self.loadNodesResult = loadNodesResult
        self.clearNodesResult = clearNodesResult
        self.saveNodeResult = saveNodeResult
        self.clearNodeResult = clearNodeResult
    }
    
    public func loadNodes() async throws -> [RecentlyOpenedNodeEntity] {
        messages.append(.loadNodes)
        return try loadNodesResult.get()
    }
    
    public func clearNodes() throws {
        messages.append(.clearNodes)
        try clearNodesResult.get()
    }
    
    public func saveNode(recentlyOpenedNode: RecentlyOpenedNodeEntity) throws {
        messages.append(.saveNode(recentlyOpenedNode))
        try saveNodeResult.get()
    }
    
    public func clearNode(for fingerprint: String) async throws(RecentlyOpenedNodesErrorEntity) {
        messages.append(.clearNode)
        try clearNodeResult.get()
    }
}
