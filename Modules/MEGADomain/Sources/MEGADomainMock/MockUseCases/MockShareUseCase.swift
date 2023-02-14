import MEGADomain

public struct MockShareUseCase: ShareUseCaseProtocol {
    private let nodes: [NodeEntity]
    private let shares: [ShareEntity]
    private let sharedNodeHandle: HandleEntity
    
    public init(nodes: [NodeEntity], shares: [ShareEntity], sharedNodeHandle: HandleEntity = 0) {
        self.nodes = nodes
        self.shares = shares
        self.sharedNodeHandle = sharedNodeHandle
    }
    
    public func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        nodes
    }
    
    public func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        shares
    }
    
    public func createShareKey(forNode node: NodeEntity) async throws -> HandleEntity {
        sharedNodeHandle
    }
}
