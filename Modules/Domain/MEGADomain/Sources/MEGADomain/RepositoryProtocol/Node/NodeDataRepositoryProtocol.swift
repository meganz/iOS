import Foundation

public protocol NodeDataRepositoryProtocol: RepositoryProtocol {
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity
    func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int)
    func nameForNode(handle: HandleEntity) -> String?
    func nameForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String?
    func sizeForNode(handle: HandleEntity) -> UInt64?
    func sizeForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> UInt64?
    func base64ForNode(handle: HandleEntity) -> String?
    func base64ForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String?
    func fingerprintForFile(at path: String) -> String?
    func setNodeCoordinates(nodeHandle: HandleEntity, latitude: Double, longitude: Double)
    func creationDateForNode(handle: HandleEntity) -> Date?
}
