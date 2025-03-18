public protocol NodeActionUseCaseProtocol: Sendable {
    
    /// Fetch the filesystem in MEGA
    func fetchNodes() async throws
    
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
    
    /// Remove the nodes link from the MEGA account
    /// - Parameters:
    ///   - nodes: nodes to remove its links
    func removeLink(nodes: [NodeEntity]) async throws
    
    /// Set sensitive attribute on the nodes
    /// - Parameter nodes: nodes to set attribute
    func hide(nodes: [NodeEntity]) async -> [HandleEntity: Result<NodeEntity, any Error>]
    
    /// Remove sensitive attribute on the nodes
    /// - Parameter nodes: nodes to set attribute
    func unhide(nodes: [NodeEntity]) async -> [HandleEntity: Result<NodeEntity, any Error>]
}

public struct NodeActionUseCase<T: NodeActionRepositoryProtocol>: NodeActionUseCaseProtocol {
    private let repo: T
    private let maxSetSensitivityTasks: Int
    
    public init(
        repo: T,
        maxSetSensitivityTasks: Int = 10
    ) {
        self.repo = repo
        self.maxSetSensitivityTasks = maxSetSensitivityTasks
    }
    
    public func fetchNodes() async throws {
        try await repo.fetchNodes()
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
    
    public func removeLink(nodes: [NodeEntity]) async throws {
        try await repo.removeLink(nodes: nodes)
    }
    
    public func hide(nodes: [NodeEntity]) async -> [HandleEntity: Result<NodeEntity, any Error>] {
        await setSensitive(nodes: nodes, sensitive: true)
    }
    
    public func unhide(nodes: [NodeEntity]) async -> [HandleEntity: Result<NodeEntity, any Error>] {
        await setSensitive(nodes: nodes, sensitive: false)
    }
    
    // MARK: Private
    
    private func setSensitive(nodes: [NodeEntity], sensitive: Bool) async -> [HandleEntity: Result<NodeEntity, any Error>] {
        await withTaskGroup(of: (handle: HandleEntity, resultType: Result<NodeEntity, any Error>).self) { group in
            let maxConcurrentTasks = min(maxSetSensitivityTasks, nodes.count)
            var iterator = nodes.makeIterator()
            
            for _ in 0..<maxConcurrentTasks {
                guard let node = iterator.next() else { break }
                guard node.isMarkedSensitive != sensitive else { continue }
                group.addTask {
                    (node.handle, await setSensitive(node: node, sensitive: sensitive))
                }
            }
            
            var results = [HandleEntity: Result<NodeEntity, any Error>]()
            while let (nodeHandle, result) = await group.next() {
                if let node = iterator.next(),
                   node.isMarkedSensitive != sensitive {
                    group.addTask {
                        (node.handle, await setSensitive(node: node, sensitive: sensitive))
                    }
                }
                results[nodeHandle] = result
            }
            return results
        }
    }
    
    private func setSensitive(node: NodeEntity, sensitive: Bool) async -> Result<NodeEntity, any Error> {
        do {
            let updatedNode = try await repo.setSensitive(node: node, sensitive: sensitive)
            return .success(updatedNode)
        } catch {
            return .failure(error)
        }
    }
}
