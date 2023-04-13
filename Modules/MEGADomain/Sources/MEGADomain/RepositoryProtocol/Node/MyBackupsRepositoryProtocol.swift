import Foundation

public protocol MyBackupsRepositoryProtocol {
    func isBackupRootNodeEmpty() async -> Bool
    func isBackupDeviceFolder(_ node: NodeEntity) -> Bool
    func isBackupNode(_ node: NodeEntity) -> Bool
    func isMyBackupsRootNode(_ node: NodeEntity) -> Bool
    func backupRootNodeSize() async throws -> UInt64
    func myBackupRootNode() async throws -> NodeEntity
}
