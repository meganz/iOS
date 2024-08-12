import Foundation

public protocol BackupsRepositoryProtocol: Sendable {
    func isBackupRootNodeEmpty() async -> Bool
    func isBackupDeviceFolder(_ node: NodeEntity) -> Bool
    func isBackupNode(_ node: NodeEntity) -> Bool
    func isBackupsRootNode(_ node: NodeEntity) -> Bool
    func backupRootNode() async throws -> NodeEntity
}
