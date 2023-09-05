import MEGADomain

public final class MockNodeActionRepository: NodeActionRepositoryProtocol {
    
    public static let newRepo = MockNodeActionRepository()
    private let createFolderResult: Result<NodeEntity, Error>
    
    public var createFolderName: String?
    
    public init(createFolderResult: Result<NodeEntity, Error> = .failure(GenericErrorEntity())) {
        self.createFolderResult = createFolderResult
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
}
