import MEGADomain
import Foundation

public struct MockNodeRepository: NodeRepositoryProtocol {
    public static let newRepo = MockNodeRepository()
    
    private let node: NodeEntity?
    private let rubbisNode: NodeEntity?
    private let nodeRoot: NodeEntity?
    private let nodeAccessLevel: NodeAccessTypeEntity
    private let childNodeNamed: NodeEntity?
    private let childNode: NodeEntity?
    private let images: [NodeEntity]
    private let fileLinkNode: NodeEntity?

    public init(node: NodeEntity? = nil, rubbishNode: NodeEntity? = nil, nodeRoot: NodeEntity? = nil, nodeAccessLevel: NodeAccessTypeEntity = .unknown, childNodeNamed: NodeEntity? = nil, childNode: NodeEntity? = nil, images: [NodeEntity] = [], fileLinkNode: NodeEntity? = nil) {
        self.node = node
        self.rubbisNode = rubbishNode
        self.nodeRoot = nodeRoot
        self.nodeAccessLevel = nodeAccessLevel
        self.childNodeNamed = childNodeNamed
        self.childNode = childNode
        self.images = images
        self.fileLinkNode = fileLinkNode
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        node
    }
    
    public func nodeFor(fileLink: FileLinkEntity, completion: @escaping (Result<NodeEntity, NodeErrorEntity>) -> Void) {
        guard let node = fileLinkNode else {
            completion(.failure(.nodeNotFound))
            return
        }
        completion(.success(node))
    }
    
    public func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity {
        guard let node = fileLinkNode else {
            throw NodeErrorEntity.nodeNotFound
        }
        return node
    }
    
    public func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> NodeEntity? {
        node
    }
    
    public func childNodeNamed(name: String, in parentHandle: HandleEntity) -> NodeEntity? {
        childNode
    }
    
    public func images(for parentNode: NodeEntity) -> [NodeEntity] {
        images
    }
    
    public func images(for parentHandle: HandleEntity) -> [NodeEntity] {
        images
    }
    
    public func rubbishNode() -> NodeEntity? {
        rubbisNode
    }
    
    public func rootNode() -> NodeEntity? {
        nodeRoot
    }
    
    public func parents(of node: NodeEntity) async -> [NodeEntity] {
        []
    }
}
