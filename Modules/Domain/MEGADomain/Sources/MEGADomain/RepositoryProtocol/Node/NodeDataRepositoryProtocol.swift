import Foundation

public protocol NodeDataRepositoryProtocol: RepositoryProtocol, Sendable {
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity
    func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int)
    func sizeForNode(handle: HandleEntity) -> UInt64?
    func folderInfo(node: NodeEntity) async throws -> FolderInfoEntity?
    func folderLinkInfo(_ folderLink: String) async throws -> FolderLinkInfoEntity?
    func creationDateForNode(handle: HandleEntity) -> Date?
    /// This one will be deprecated soon, please use the async version instead to avoid app hang due to sdkMutex
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity?
    func nodeForHandle(_ handle: HandleEntity) async -> NodeEntity?
    func parentForHandle(_ handle: HandleEntity) -> NodeEntity?
}
