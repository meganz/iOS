public protocol RecentlyOpenedNodesUseCaseProtocol: Sendable {
    func loadNodes() async throws -> [RecentlyOpenedNodeEntity]
    func clearNodes() async throws
    func saveNode(recentlyOpenedNode: RecentlyOpenedNodeEntity) throws
}

public struct RecentlyOpenedNodesUseCase: RecentlyOpenedNodesUseCaseProtocol {
    
    private let recentlyOpenedNodeRepository: any RecentlyOpenedNodesRepositoryProtocol
    
    public init(recentlyOpenedNodesRepository: some RecentlyOpenedNodesRepositoryProtocol) {
        self.recentlyOpenedNodeRepository = recentlyOpenedNodesRepository
    }
    
    public func loadNodes() async throws -> [RecentlyOpenedNodeEntity] {
        try await recentlyOpenedNodeRepository.loadNodes()
    }
    
    public func clearNodes() async throws {
        try await recentlyOpenedNodeRepository.clearNodes()
    }
    
    public func saveNode(recentlyOpenedNode: RecentlyOpenedNodeEntity) throws {
        try recentlyOpenedNodeRepository.saveNode(recentlyOpenedNode: recentlyOpenedNode)
    }
}
