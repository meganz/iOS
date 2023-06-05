@testable import MEGA

struct MockNameCollisionUseCase: NameCollisionUseCaseProtocol {
    var nameCollisions: [NameCollisionEntity]?
    var copiedNodes: [NodeHandle]?
    var movedNodes: [NodeHandle]?
    var nodeSize: String?
    var nodeCrationDate: String?
    var fileSize: String?
    var fileCrationDate: String?
    var nodeRename: String?
    var node: NodeEntity?
    
    func resolveNameCollisions(for collisions: [NameCollisionEntity]) -> [NameCollisionEntity] {
        nameCollisions ?? []
    }
    
    func copyNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity], isFolderLink: Bool) async throws -> [NodeHandle] {
        copiedNodes ?? []
    }
    
    func moveNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity]) async throws -> [NodeHandle] {
        movedNodes ?? []
    }
    
    func sizeForNode(handle: MEGAHandle) -> String {
        nodeSize ?? ""
    }
    
    func creationDateForNode(handle: MEGAHandle) -> String {
        nodeCrationDate ?? ""
    }
    
    func sizeForFile(at url: URL) -> String {
        fileSize ?? ""
    }
    
    func creationDateForFile(at url: URL) -> String {
        fileCrationDate ?? ""
    }
    
    func renameNode(named name: NSString, inParent parentHandle: MEGAHandle) -> String {
        nodeRename ?? ""
    }
    
    func node(for handle: MEGAHandle) -> NodeEntity? {
        node
    }
}
