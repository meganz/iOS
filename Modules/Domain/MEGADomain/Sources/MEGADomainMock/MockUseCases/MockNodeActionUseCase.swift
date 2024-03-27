import MEGADomain

public struct MockNodeActionUseCase: NodeActionUseCaseProtocol {
    private let nodeResult: Result<Void, Error>
    private let nodeEntityResult: Result<NodeEntity, Error>
    private let hideUnhideResult: [HandleEntity: Result<NodeEntity, any Error>]
    
    public init(nodeResult: Result<Void, Error> = .failure(GenericErrorEntity()),
                nodeEntityResult: Result<NodeEntity, Error> = .failure(GenericErrorEntity()),
                hideUnhideResult: [HandleEntity: Result<NodeEntity, any Error>] = [:]) {
        self.nodeResult = nodeResult
        self.nodeEntityResult = nodeEntityResult
        self.hideUnhideResult = hideUnhideResult
    }
    
    public func fetchNodes() async throws {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: nodeResult)
        }
    }
    
    public func createFolder(name: String, parent: NodeEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: nodeEntityResult)
        }
    }
    
    public func rename(node: NodeEntity, name: String) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: nodeEntityResult)
        }
    }
    
    public func trash(node: NodeEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: nodeEntityResult)
        }
    }
    
    public func untrash(node: NodeEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: nodeEntityResult)
        }
    }
    
    public func delete(node: NodeEntity) async throws {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: nodeResult)
        }
    }
    
    public func move(node: NodeEntity, toParent: NodeEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: nodeEntityResult)
        }
    }
    
    public func removeLink(nodes: [NodeEntity]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: nodeResult)
        }
    }
    
    public func hide(nodes: [NodeEntity]) async -> [HandleEntity: Result<NodeEntity, any Error>] {
        hideUnhideResult
    }
    
    public func unhide(nodes: [NodeEntity]) async -> [HandleEntity: Result<NodeEntity, any Error>] {
        hideUnhideResult
    }
}
