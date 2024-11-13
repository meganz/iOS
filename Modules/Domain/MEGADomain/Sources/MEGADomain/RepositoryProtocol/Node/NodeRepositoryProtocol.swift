import MEGASwift

public protocol NodeRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Node updates from `MEGAGlobalDelegate` `onNodesUpdate`
    ///
    /// - Returns: `AnyAsyncSequence` that will yield `[NodeEntity]` items until sequence terminated.
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity?
    func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity
    func childNodeNamed(name: String, in parentHandle: HandleEntity) -> NodeEntity?
    /// Get the child node with provided name and type
    /// - Parameters:
    ///   - parent: parent node to look for child node
    ///   - name: name of node
    ///   - type: node type
    /// - Returns: The child node of parent or nil if not found.
    func childNode(parent node: NodeEntity,
                   name: String,
                   type: NodeTypeEntity) async -> NodeEntity?
    func rubbishNode() -> NodeEntity?
    func rootNode() -> NodeEntity?
    func parents(of node: NodeEntity) async -> [NodeEntity]
    func asyncChildren(of node: NodeEntity, sortOrder: SortOrderEntity) async -> NodeListEntity?
    func children(of node: NodeEntity) -> NodeListEntity?
    func childrenNames(of node: NodeEntity) -> [String]?
    func isInRubbishBin(node: NodeEntity) -> Bool
    func createFolder(with name: String, in parent: NodeEntity) async throws -> NodeEntity
    /// Ascertain if the node's ancestor is marked as sensitive
    ///  - Parameters: node - the node to check
    ///  - Returns: true if the node's ancestor is marked as sensitive
    ///  - Throws: `NodeError.nodeNotFound` if the parent node cant be found
    func isInheritingSensitivity(node: NodeEntity) async throws -> Bool
    /// Ascertain if the node's ancestor is marked as sensitive
    ///  - Parameters: node - the node to check
    ///  - Returns: true if the node's ancestor is marked as sensitive
    ///  - Throws: `NodeError.nodeNotFound` if the parent node cant be found
    /// - Important: This could possibly block the calling thread, make sure not to call it on main thread.
    func isInheritingSensitivity(node: NodeEntity) throws -> Bool
}
