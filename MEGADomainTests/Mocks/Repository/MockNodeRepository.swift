@testable import MEGA
import MEGADomain

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
    var fileLinkNode: NodeEntity?
    
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        node
    }

    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        nodeAccessLevel
    }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        labelString
    }
    
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFoldersCount
    }
    
    func hasVersions(nodeHandle: HandleEntity) -> Bool {
        hasVersions
    }
    
    func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        isDownloaded
    }
    
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        isInRubbishBin
    }
    
    func nameForNode(handle: HandleEntity) -> String? {
        name
    }
    
    func nameForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String? {
        name
    }
    
    func nodeNameFor(fileLink: FileLinkEntity) async throws -> String {
        guard let name = name else {
            throw NodeErrorEntity.nodeNameNotFound
        }
        return name
    }
    
    func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity {
        guard let node = fileLinkNode else {
            throw NodeErrorEntity.nodeNotFound
        }
        return node
    }

    func sizeForNode(handle: HandleEntity) -> UInt64? {
        size
    }
    
    func sizeForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> UInt64? {
        size
    }
    
    func base64ForNode(handle: HandleEntity) -> String? {
        base64Handle
    }
    
    func base64ForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String? {
        base64Handle
    }
    
    func isFileNode(handle: HandleEntity) -> Bool {
        isFile
    }
    
    func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: HandleEntity, newName: String?) -> Bool {
        copiedNodeIfExists
    }
    
    func copyNode(handle: HandleEntity, in parentHandle: HandleEntity, newName: String?, isFolderLink: Bool) async throws -> HandleEntity {
        guard let copiedNodeHandle = copiedNodeHandle else {
            throw CopyOrMoveErrorEntity.generic
        }
        return copiedNodeHandle
    }
    
    func moveNode(handle: HandleEntity, in parentHandle: HandleEntity, newName: String?) async throws -> HandleEntity {
        guard let movedNodeHandle = movedNodeHandle else {
            throw CopyOrMoveErrorEntity.generic
        }
        return movedNodeHandle
    }
    
    func fingerprintForFile(at path: String) -> String? {
        fingerprint
    }
    
    func setNodeCoordinates(nodeHandle: HandleEntity, latitude: Double, longitude: Double) {    }
    
    func existChildNodeNamed(name: String, in parentHandle: HandleEntity) -> Bool {
        existsChildNode
    }
    
    func childNodeNamed(name: String, in parentHandle: HandleEntity) -> NodeEntity? {
        childNode
    }
    
    func creationDateForNode(handle: HandleEntity) -> Date? {
        modificationDate
    }
    
    func images(for parentNode: NodeEntity) -> [NodeEntity] {
        images
    }
    
    func images(for parentHandle: HandleEntity) -> [NodeEntity] {
        images
    }
}
