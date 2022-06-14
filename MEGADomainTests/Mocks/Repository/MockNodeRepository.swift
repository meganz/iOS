@testable import MEGA

struct MockNodeRepository: NodeRepositoryProtocol {
    var node: NodeEntity?
    var name: String?
    var size: UInt64?
    var base64Handle: String?
    var isFile: Bool = false
    var copiedNodeIfExists: Bool = false
    var fingerprint: String?
    var childNode: NodeEntity?
    var modificationDate: Date = Date()
    var copiedNodeHandle: UInt64?
    var movedNodeHandle: UInt64?

    func nodeForHandle(_ handle: MEGAHandle) -> NodeEntity? {
        node
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
    
    func childNodeNamed(name: String, in parentHandle: MEGAHandle) -> NodeEntity? {
        childNode
    }
    
    func creationDateForNode(handle: MEGAHandle) -> Date? {
        modificationDate
    }
}
