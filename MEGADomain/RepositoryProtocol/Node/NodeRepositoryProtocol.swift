
protocol NodeRepositoryProtocol: RepositoryProtocol {
    func nodeForHandle(_ handle: MEGAHandle) -> NodeEntity?
    func nameForNode(handle: MEGAHandle) -> String?
    func nameForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> String?
    func sizeForNode(handle: MEGAHandle) -> UInt64?
    func sizeForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> UInt64?
    func base64ForNode(handle: MEGAHandle) -> String?
    func base64ForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> String?
    func isFileNode(handle: MEGAHandle) -> Bool
    func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: MEGAHandle, newName: String?) -> Bool
    func copyNode(handle: NodeHandle, in parentHandle: NodeHandle, newName: String?, isFolderLink: Bool) async throws -> NodeHandle
    func moveNode(handle: NodeHandle, in parentHandle: NodeHandle, newName: String?) async throws -> NodeHandle
    func fingerprintForFile(at path: String) -> String?
    func setNodeCoordinates(nodeHandle: MEGAHandle, latitude: Double, longitude: Double)
    func childNodeNamed(name: String, in parentHandle: MEGAHandle) -> NodeEntity?
    func creationDateForNode(handle: MEGAHandle) -> Date?
}
