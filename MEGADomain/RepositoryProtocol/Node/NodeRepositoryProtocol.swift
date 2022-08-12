import MEGADomain

protocol NodeRepositoryProtocol: RepositoryProtocol {
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions(nodeHandle: HandleEntity) -> Bool
    func isDownloaded(nodeHandle: HandleEntity) -> Bool
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity?
    func nameForNode(handle: HandleEntity) -> String?
    func nameForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String?
    func nodeFor(fileLink: FileLinkEntity, completion: @escaping (Result<NodeEntity, NodeErrorEntity>) -> Void)
    func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity
    func sizeForNode(handle: HandleEntity) -> UInt64?
    func sizeForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> UInt64?
    func base64ForNode(handle: HandleEntity) -> String?
    func base64ForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String?
    func isFileNode(handle: HandleEntity) -> Bool
    func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: HandleEntity, newName: String?) -> Bool
    func copyNode(handle: HandleEntity, in parentHandle: HandleEntity, newName: String?, isFolderLink: Bool) async throws -> HandleEntity
    func moveNode(handle: HandleEntity, in parentHandle: HandleEntity, newName: String?) async throws -> HandleEntity
    func fingerprintForFile(at path: String) -> String?
    func setNodeCoordinates(nodeHandle: HandleEntity, latitude: Double, longitude: Double)
    func childNodeNamed(name: String, in parentHandle: HandleEntity) -> NodeEntity?
    func creationDateForNode(handle: HandleEntity) -> Date?
    func images(for parentNode: NodeEntity) -> [NodeEntity]
    func images(for parentHandle: HandleEntity) -> [NodeEntity]
}
