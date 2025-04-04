import MEGADomain

public final class MockNodeActionRepository: NodeActionRepositoryProtocol, @unchecked Sendable {
    
    public static let newRepo = MockNodeActionRepository()
    private let createFolderResult: Result<NodeEntity, any Error>
    private let setSensitiveResults: [HandleEntity: Result<NodeEntity, any Error>]
    
    public var createFolderName: String?
    public var sensitive: Bool?
    
    public init(createFolderResult: Result<NodeEntity, any Error> = .failure(GenericErrorEntity()),
                setSensitiveResults: [HandleEntity: Result<NodeEntity, any Error>] = [:]) {
        self.createFolderResult = createFolderResult
        self.setSensitiveResults = setSensitiveResults
    }
    
    public func fetchNodes() async throws {}
    
    public func createFolder(name: String, parent: NodeEntity) async throws -> NodeEntity {
        createFolderName = name
        return try await withCheckedThrowingContinuation {
            $0.resume(with: createFolderResult)
        }
    }
    
    public func rename(node: NodeEntity, name: String) async throws -> NodeEntity {
        NodeEntity(name: name, handle: node.handle)
    }
    
    public func trash(node: NodeEntity) async throws -> NodeEntity {
        NodeEntity(handle: node.handle)
    }
    
    public func untrash(node: NodeEntity) async throws -> NodeEntity {
        NodeEntity(handle: node.handle)
    }
    
    public func delete(node: NodeEntity) async throws {}
    
    public func move(node: NodeEntity, toParent: NodeEntity) async throws -> NodeEntity {
        NodeEntity(handle: node.handle, parentHandle: toParent.handle)
    }
    
    public func removeLink(nodes: [NodeEntity]) async throws {}
    
    public func setSensitive(node: NodeEntity, sensitive: Bool) async throws -> NodeEntity {
        self.sensitive = sensitive
        guard let setSensitiveResult = setSensitiveResults.first(where: { $0.key == node.handle })?.value else {
            return NodeEntity(handle: .invalid)
        }
        return try await withCheckedThrowingContinuation {
            $0.resume(with: setSensitiveResult)
        }
    }
}
