public protocol NodeActionUseCaseProtocol {
    
    /// Fetch the filesystem in MEGA
    func fetchnodes() async throws
    
    /// Create a folder in the MEGA account
    /// - Parameters:
    ///   - name: name of the new folder
    ///   - parent: parent folder
    /// - Returns: the node folder created
    func createFolder(name: String, parent: NodeEntity) async throws -> NodeEntity
    
    /// Rename a node in the MEGA account
    /// - Parameters:
    ///   - node: node to rename
    ///   - name: new name for the node
    /// - Returns: the node renamed
    func rename(node: NodeEntity, name: String) async throws -> NodeEntity
    
    /// Move a node to the Rubbish Bin in the MEGA account
    /// - Parameter node: node to move to the Rubbish Bin
    /// - Returns: the node moved to the Rubbish Bin
    func trash(node: NodeEntity) async throws -> NodeEntity
    
    /// Restore a node from the Rubbish Bin in the MEGA account
    /// - Parameter node: node to restore from the Rubbish Bin
    /// - Returns: the node restored from the Rubbish Bin
    func untrash(node: NodeEntity) async throws -> NodeEntity
    
    /// Remove a node from the MEGA account
    /// - Parameter node: node to remove
    func delete(node: NodeEntity) async throws
    
    /// Move a node in the MEGA account
    /// - Parameters:
    ///   - node: node to move
    ///   - toParent: new parent for the node
    /// - Returns: the node moved
    func move(node: NodeEntity, toParent: NodeEntity) async throws -> NodeEntity
}

public struct NodeActionUseCase<T: NodeActionRepositoryProtocol>: NodeActionUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func fetchnodes() async throws {
        try await repo.fetchnodes()
    }
    
    public func createFolder(name: String, parent: NodeEntity) async throws -> NodeEntity {
        try await repo.createFolder(name: name, parent: parent)
    }
    
    public func rename(node: NodeEntity, name: String) async throws -> NodeEntity {
        try await repo.rename(node: node, name: name)
    }
    
    public func trash(node: NodeEntity) async throws -> NodeEntity {
        try await repo.trash(node: node)
    }
    
    public func untrash(node: NodeEntity) async throws -> NodeEntity {
        try await repo.untrash(node: node)
    }
    
    public func delete(node: NodeEntity) async throws {
        try await repo.delete(node: node)
    }
    
    public func move(node: NodeEntity, toParent: NodeEntity) async throws -> NodeEntity {
        try await repo.move(node: node, toParent: toParent)
    }
}
