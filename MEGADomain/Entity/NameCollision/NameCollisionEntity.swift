
final class NameCollisionEntity: NSObject {
    let parentHandle: HandleEntity
    let name: String
    let isFile: Bool
    let fileUrl: URL?
    let nodeHandle: HandleEntity?
    var renamed: String?
    var collisionAction: NameCollisionActionType?
    var collisionNodeHandle: HandleEntity?
    
    init(parentHandle: HandleEntity, name: String, isFile: Bool, fileUrl: URL? = nil, nodeHandle: HandleEntity? = nil) {
        self.parentHandle = parentHandle
        self.name = name
        self.isFile = isFile
        self.fileUrl = fileUrl
        self.nodeHandle = nodeHandle
        self.collisionAction = nil
        self.collisionNodeHandle = nil
    }
}
