public protocol NodeActionRepositoryProtocol: RepositoryProtocol, Sendable {
    func fetchNodes() async throws
    func createFolder(name: String, parent: NodeEntity) async throws -> NodeEntity
    func rename(node: NodeEntity, name: String) async throws -> NodeEntity
    func trash(node: NodeEntity) async throws -> NodeEntity
    func untrash(node: NodeEntity) async throws -> NodeEntity
    func delete(node: NodeEntity) async throws
    func move(node: NodeEntity, toParent: NodeEntity) async throws -> NodeEntity
    func removeLink(nodes: [NodeEntity]) async throws
    
    /// Set sensitive attribute on the node
    /// - Parameters:
    ///   - node: node to set attribute
    ///   - sensitive: true sets the sensitive attribute otherwise removes it
    func setSensitive(node: NodeEntity, sensitive: Bool) async throws -> NodeEntity
}
