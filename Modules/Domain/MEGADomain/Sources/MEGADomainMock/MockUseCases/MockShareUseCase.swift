import MEGADomain

public struct MockShareUseCase: ShareUseCaseProtocol {
    private let nodes: [NodeEntity]
    private let shares: [ShareEntity]
    private let sharedNodeHandles: [HandleEntity]
    private let areUserCredentialsVerified: Bool
    private let user: UserEntity?
    
    public init(
        nodes: [NodeEntity] = [],
        shares: [ShareEntity] = [],
        sharedNodeHandles: [HandleEntity] = [],
        areUserCredentialsVerified: Bool = false,
        user: UserEntity? = nil
    ) {
        self.nodes = nodes
        self.shares = shares
        self.sharedNodeHandles = sharedNodeHandles
        self.areUserCredentialsVerified = areUserCredentialsVerified
        self.user = user
    }
    
    public func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        nodes
    }
    
    public func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        shares
    }

    public func areCredentialsVerifed(of user: UserEntity) -> Bool {
        areUserCredentialsVerified
    }

    public func user(from node: NodeEntity) -> UserEntity? {
        user
    }
    
    public func createShareKeys(forNodes nodes: [NodeEntity]) async throws -> [HandleEntity] {
        sharedNodeHandles
    }
}
