public protocol NodeActionRepositoryProtocol: RepositoryProtocol {
    func fetchnodes() async throws
    func createFolder(name: String, parent: NodeEntity) async throws -> NodeEntity
    func rename(node: NodeEntity, name: String) async throws -> NodeEntity
    func trash(node: NodeEntity) async throws -> NodeEntity
    func untrash(node: NodeEntity) async throws -> NodeEntity
    func delete(node: NodeEntity) async throws
    func move(node: NodeEntity, toParent: NodeEntity) async throws -> NodeEntity
    func removeLink(nodes: [NodeEntity]) async throws
}
