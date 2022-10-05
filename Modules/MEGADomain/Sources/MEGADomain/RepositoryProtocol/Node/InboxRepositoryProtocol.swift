import Foundation

public protocol InboxRepositoryProtocol {
    func containsInboxRootNode(_ array: [NodeEntity]) -> Bool
    func isInboxRootNode(_ node: NodeEntity) -> Bool
    func backupRootNodeSize() async throws -> UInt64
    func isBackupDeviceFolder(_ node: NodeEntity) -> Bool
    func isBackupRootNodeEmpty() async -> Bool
    func inboxNode() -> NodeEntity?
    func myBackupRootNode() async throws -> NodeEntity
}
