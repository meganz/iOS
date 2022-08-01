import MEGADomain

protocol NodeRepositoryProtocol: RepositoryProtocol {
    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: MEGAHandle) -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions(nodeHandle: MEGAHandle) -> Bool
    func isDownloaded(nodeHandle: MEGAHandle) -> Bool
    func isInRubbishBin(nodeHandle: MEGAHandle) -> Bool
    func nodeForHandle(_ handle: MEGAHandle) -> NodeEntity?
    func nameForNode(handle: MEGAHandle) -> String?
    func nameForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> String?
    func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity
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
    func images(for parentNode: NodeEntity) -> [NodeEntity]
    func images(for parentHandle: MEGAHandle) -> [NodeEntity]
}
