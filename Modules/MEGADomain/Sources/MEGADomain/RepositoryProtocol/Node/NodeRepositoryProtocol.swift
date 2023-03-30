import Foundation

public protocol NodeRepositoryProtocol: RepositoryProtocol {
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity?
    func nodeFor(fileLink: FileLinkEntity, completion: @escaping (Result<NodeEntity, NodeErrorEntity>) -> Void)
    func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity
    func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> NodeEntity?
    func childNodeNamed(name: String, in parentHandle: HandleEntity) -> NodeEntity?
    func images(for parentNode: NodeEntity) -> [NodeEntity]
    func images(for parentHandle: HandleEntity) -> [NodeEntity]
    func rubbishNode() -> NodeEntity?
    func rootNode() -> NodeEntity?
    func parents(of node: NodeEntity) async -> [NodeEntity]
}
