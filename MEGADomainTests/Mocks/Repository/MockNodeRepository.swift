@testable import MEGA

struct MockNodeRepository: NodeRepositoryProtocol {
    static let newRepo = MockNodeRepository()
    
    var node: NodeEntity?
    
    var nodeAccessLevel:NodeAccessTypeEntity = .unknown
    var isDownloaded: Bool = false
    var hasVersions: Bool = false
    var isInRubbishBin: Bool = false
    var labelString: String = ""
    var childNodeNamed: NodeEntity?
    var filesAndFoldersCount: (Int, Int) = (0, 0)
    var name: String?
    var size: UInt64?
    var base64Handle: String?
    var isFile: Bool = false
    var copiedNodeIfExists: Bool = false
    var fingerprint: String?
    var existsChildNode: Bool = false
    var childNode: NodeEntity?
    var modificationDate: Date = Date()
    var copiedNodeHandle: UInt64?
    var movedNodeHandle: UInt64?
    var images: [NodeEntity] = []

    func nodeForHandle(_ handle: MEGAHandle) -> NodeEntity? {
        node
    }

    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity {
        nodeAccessLevel
    }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        labelString
    }
    
    func getFilesAndFolders(nodeHandle: MEGAHandle) -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFoldersCount
    }
    
    func hasVersions(nodeHandle: MEGAHandle) -> Bool {
        hasVersions
    }
    
    func isDownloaded(nodeHandle: MEGAHandle) -> Bool {
        isDownloaded
    }
    
    func isInRubbishBin(nodeHandle: MEGAHandle) -> Bool {
        isInRubbishBin
    }
    
    func nameForNode(handle: MEGAHandle) -> String? {
        name
    }
    
    func nameForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> String? {
        name
    }
    
    func sizeForNode(handle: MEGAHandle) -> UInt64? {
        size
    }
    
    func sizeForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> UInt64? {
        size
    }
    
    func base64ForNode(handle: MEGAHandle) -> String? {
        base64Handle
    }
    
    func base64ForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> String? {
        base64Handle
    }
    
    func isFileNode(handle: MEGAHandle) -> Bool {
        isFile
    }
    
    func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: MEGAHandle, newName: String?) -> Bool {
        copiedNodeIfExists
    }
    
    func copyNode(handle: NodeHandle, in parentHandle: NodeHandle, newName: String?, isFolderLink: Bool) async throws -> NodeHandle {
        guard let copiedNodeHandle = copiedNodeHandle else {
            throw CopyOrMoveErrorEntity.generic
        }
        return copiedNodeHandle
    }
    
    func moveNode(handle: NodeHandle, in parentHandle: NodeHandle, newName: String?) async throws -> NodeHandle {
        guard let movedNodeHandle = movedNodeHandle else {
            throw CopyOrMoveErrorEntity.generic
        }
        return movedNodeHandle
    }
    
    func fingerprintForFile(at path: String) -> String? {
        fingerprint
    }
    
    func setNodeCoordinates(nodeHandle: MEGAHandle, latitude: Double, longitude: Double) {    }
    
    func existChildNodeNamed(name: String, in parentHandle: MEGAHandle) -> Bool {
        existsChildNode
    }
    
    func childNodeNamed(name: String, in parentHandle: MEGAHandle) -> NodeEntity? {
        childNode
    }
    
    func creationDateForNode(handle: MEGAHandle) -> Date? {
        modificationDate
    }
    
    func images(for parentNode: NodeEntity) -> [NodeEntity] {
        images
    }
    
    func images(for parentHandle: MEGAHandle) -> [NodeEntity] {
        images
    }
}
