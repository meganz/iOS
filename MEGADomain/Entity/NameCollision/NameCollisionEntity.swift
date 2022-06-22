
final class NameCollisionEntity: NSObject {
    let parentHandle: MEGAHandle
    let name: String
    let isFile: Bool
    let fileUrl: URL?
    let nodeHandle: MEGAHandle?
    var renamed: String?
    var collisionAction: NameCollisionActionType?
    var collisionNodeHandle: MEGAHandle?
    
    init(parentHandle: MEGAHandle, name: String, isFile: Bool, fileUrl: URL? = nil, nodeHandle: MEGAHandle? = nil) {
        self.parentHandle = parentHandle
        self.name = name
        self.isFile = isFile
        self.fileUrl = fileUrl
        self.nodeHandle = nodeHandle
        self.collisionAction = nil
        self.collisionNodeHandle = nil
    }
}
