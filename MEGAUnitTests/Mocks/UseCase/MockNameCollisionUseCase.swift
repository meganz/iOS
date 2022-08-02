@testable import MEGA

struct MockNameCollisionUseCase: NameCollisionUseCaseProtocol {
    var nameCollisions: [NameCollisionEntity]?
    var copiedNodes: [HandleEntity]?
    var movedNodes: [HandleEntity]?
    var nodeSize: String?
    var nodeCrationDate: String?
    var fileSize: String?
    var fileCrationDate: String?
    var nodeRename: String?
    var node: NodeEntity?
    
    
    func resolveNameCollisions(for collisions: [NameCollisionEntity]) -> [NameCollisionEntity] {
        nameCollisions ?? []
    }
    
    func copyNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity], isFolderLink: Bool) async throws -> [HandleEntity] {
        copiedNodes ?? []
    }
    
    func moveNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity]) async throws -> [HandleEntity] {
        movedNodes ?? []
    }
    
    func sizeForNode(handle: HandleEntity) -> String {
        nodeSize ?? ""
    }
    
    func creationDateForNode(handle: HandleEntity) -> String {
        nodeCrationDate ?? ""
    }
    
    func sizeForFile(at url: URL) -> String {
        fileSize ?? ""
    }
    
    func creationDateForFile(at url: URL) -> String {
        fileCrationDate ?? ""
    }
    
    func renameNode(named name: NSString, inParent parentHandle: HandleEntity) -> String {
        nodeRename ?? ""
    }
    
    func node(for handle: HandleEntity) -> NodeEntity? {
        node
    }
}
