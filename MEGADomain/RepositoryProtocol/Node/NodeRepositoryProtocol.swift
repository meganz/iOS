
protocol NodeRepositoryProtocol {
    func nameForNode(handle: MEGAHandle) -> String?
    func nameForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> String?
    func sizeForNode(handle: MEGAHandle) -> UInt64?
    func sizeForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> UInt64?
    func base64ForNode(handle: MEGAHandle) -> String?
    func base64ForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> String?
    func isFileNode(handle: MEGAHandle) -> Bool
    func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: MEGAHandle) -> Bool
    func fingerprintForFile(at path: String) -> String?
    func setNodeCoordinates(nodeHandle: MEGAHandle, latitude: Double, longitude: Double)
}
