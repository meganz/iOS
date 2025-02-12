import Foundation

public protocol BackupsRepositoryProtocol: Sendable {
    func isBackupNode(_ node: NodeEntity) -> Bool
    func isBackupsRootNode(_ node: NodeEntity) -> Bool
}
