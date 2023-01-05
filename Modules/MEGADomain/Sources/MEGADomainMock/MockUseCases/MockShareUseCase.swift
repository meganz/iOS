import MEGADomain

public struct MockShareUseCase: ShareUseCaseProtocol {
    private let nodes: [NodeEntity]
    private let shares: [ShareEntity]
    
    public init(nodes: [NodeEntity], shares: [ShareEntity]) {
        self.nodes = nodes
        self.shares = shares
    }
    
    public func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        nodes
    }
    
    public func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        shares
    }
}
