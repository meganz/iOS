import Foundation
import MEGADomain

public struct MockDeviceCenterRepository: DeviceCenterRepositoryProtocol {
    public static let newRepo = MockDeviceCenterRepository()
    private let backupEntities: [BackupEntity]
    private let shouldFailRequest: Bool
    
    public init(backupEntities: [BackupEntity] = [], shouldFailRequest: Bool = false) {
        self.backupEntities = backupEntities
        self.shouldFailRequest = shouldFailRequest
    }
    
    public func backups() async throws -> [BackupEntity] {
        if shouldFailRequest {
            throw GenericErrorEntity()
        }
        return backupEntities
    }
}
