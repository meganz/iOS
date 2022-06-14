@testable import MEGA

struct MockNodeRepository: NodeRepositoryProtocol {
    var name: String?
    var size: UInt64?
    var base64Handle: String?
    var isFile: Bool = false
    var copiedNodeIfExists: Bool = false
    var fingerprint: String?

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
    
    func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: MEGAHandle) -> Bool {
        copiedNodeIfExists
    }
    
    func fingerprintForFile(at path: String) -> String? {
        fingerprint
    }
    
    func setNodeCoordinates(nodeHandle: MEGAHandle, latitude: Double, longitude: Double) {    }
}
