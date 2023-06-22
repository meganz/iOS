import Foundation
import MEGADomain

public struct MockNameCollisionUseCase: NameCollisionUseCaseProtocol {
    private let nameCollisions: [NameCollisionEntity]?
    private let copiedNodes: [HandleEntity]?
    private let movedNodes: [HandleEntity]?
    private let nodeSize: String?
    private let nodeCrationDate: String?
    private let fileSize: String?
    private let fileCrationDate: String?
    private let nodeRename: String?
    private let node: NodeEntity?
    
    public init(nameCollisions: [NameCollisionEntity]? = nil,
                copiedNodes: [HandleEntity]? = nil,
                movedNodes: [HandleEntity]? = nil,
                nodeSize: String? = nil,
                nodeCrationDate: String? = nil,
                fileSize: String? = nil,
                fileCrationDate: String? = nil,
                nodeRename: String? = nil,
                node: NodeEntity? = nil) {
    
        self.nameCollisions = nameCollisions
        self.copiedNodes = copiedNodes
        self.movedNodes = movedNodes
        self.nodeSize = nodeSize
        self.nodeCrationDate = nodeCrationDate
        self.fileSize = fileSize
        self.fileCrationDate = fileCrationDate
        self.nodeRename = nodeRename
        self.node = node
    }
    
    public func resolveNameCollisions(for collisions: [NameCollisionEntity]) -> [NameCollisionEntity] {
        nameCollisions ?? []
    }
    
    public func copyNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity], isFolderLink: Bool) async throws -> [HandleEntity] {
        copiedNodes ?? []
    }
    
    public func moveNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity]) async throws -> [HandleEntity] {
        movedNodes ?? []
    }
    
    public func sizeForNode(handle: HandleEntity) -> String {
        nodeSize ?? ""
    }
    
    public func creationDateForNode(handle: HandleEntity) -> String {
        nodeCrationDate ?? ""
    }
    
    public func sizeForFile(at url: URL) -> String {
        fileSize ?? ""
    }
    
    public func creationDateForFile(at url: URL) -> String {
        fileCrationDate ?? ""
    }
    
    public func renameNode(named name: NSString, inParent parentHandle: HandleEntity) -> String {
        nodeRename ?? ""
    }
    
    public func node(for handle: HandleEntity) -> NodeEntity? {
        node
    }
}
