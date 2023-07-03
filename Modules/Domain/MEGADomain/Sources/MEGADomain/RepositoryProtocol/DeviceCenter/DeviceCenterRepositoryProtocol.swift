import Foundation

public protocol DeviceCenterRepositoryProtocol: RepositoryProtocol {
    func backups() async throws -> [BackupEntity]
}
