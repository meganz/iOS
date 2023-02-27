import MEGADomain

public struct MockShareUseCase: ShareUseCaseProtocol {
    private let nodes: [NodeEntity]
    private let shares: [ShareEntity]
    private let sharedNodeHandles: [HandleEntity]
    
    public init(nodes: [NodeEntity], shares: [ShareEntity], sharedNodeHandles: [HandleEntity] = []) {
        self.nodes = nodes
        self.shares = shares
        self.sharedNodeHandles = sharedNodeHandles
    }
    
    public func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        nodes
    }
    
    public func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        shares
    }
    
    public func createShareKeys(forNodes nodes: [NodeEntity]) async throws -> [HandleEntity] {
        sharedNodeHandles
    }
}
