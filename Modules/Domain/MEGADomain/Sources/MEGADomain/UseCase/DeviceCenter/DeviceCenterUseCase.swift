import Foundation

public protocol DeviceCenterUseCaseProtocol {
    func backups() async throws -> [BackupEntity]
}

public struct DeviceCenterUseCase<Repository: DeviceCenterRepositoryProtocol>: DeviceCenterUseCaseProtocol {
    private let repository: Repository
    
    public init(deviceCenterRepository: Repository) {
        self.repository = deviceCenterRepository
    }
    
    public func backups() async throws -> [BackupEntity] {
        try await repository.backups()
    }
}
