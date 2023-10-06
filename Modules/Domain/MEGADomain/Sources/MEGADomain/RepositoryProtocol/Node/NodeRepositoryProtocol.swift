import Foundation

public protocol NodeRepositoryProtocol: RepositoryProtocol {
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity?
    func nodeFor(fileLink: FileLinkEntity, completion: @escaping (Result<NodeEntity, NodeErrorEntity>) -> Void)
    func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity
    func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> NodeEntity?
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
    func images(for parentNode: NodeEntity) -> [NodeEntity]
    func images(for parentHandle: HandleEntity) -> [NodeEntity]
    func rubbishNode() -> NodeEntity?
    func rootNode() -> NodeEntity?
    func parents(of node: NodeEntity) async -> [NodeEntity]
    func children(of node: NodeEntity) async -> NodeListEntity?
}
