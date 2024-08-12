import MEGADomain

public final class MockShareUseCase: ShareUseCaseProtocol {
    private let nodes: [NodeEntity]
    private let shares: [ShareEntity]
    private let sharedNodeHandles: [HandleEntity]
    private let areUserCredentialsVerified: Bool
    private let user: UserEntity?
    private let createShareKeysError: Error?
    private let containsSensitiveContent: [HandleEntity: Bool]
    
    public var userFunctionHasBeenCalled = false
    public var createShareKeyFunctionHasBeenCalled = false
    public var createShareKeysErrorHappened = false
    
    public init(
        nodes: [NodeEntity] = [],
        shares: [ShareEntity] = [],
        sharedNodeHandles: [HandleEntity] = [],
        areUserCredentialsVerified: Bool = false,
        user: UserEntity? = nil,
        createShareKeysError: Error? = nil,
        containsSensitiveContent: [HandleEntity: Bool] = [:]
    ) {
        self.nodes = nodes
        self.shares = shares
        self.sharedNodeHandles = sharedNodeHandles
        self.areUserCredentialsVerified = areUserCredentialsVerified
        self.user = user
        self.createShareKeysError = createShareKeysError
        self.containsSensitiveContent = containsSensitiveContent
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
        userFunctionHasBeenCalled = true
        
        return user
    }
    
    public func createShareKeys(forNodes nodes: [NodeEntity]) async throws -> [HandleEntity] {
        createShareKeyFunctionHasBeenCalled = true
        
        if let error = createShareKeysError {
            createShareKeysErrorHappened = true
            throw error
        }
        
        return sharedNodeHandles
    }
    
    public func containsSensitiveContent(in nodes: some Sequence<NodeEntity>) async throws -> Bool {
        nodes.contains { node in
            containsSensitiveContent[node.handle] ?? false
        }
    }
}
