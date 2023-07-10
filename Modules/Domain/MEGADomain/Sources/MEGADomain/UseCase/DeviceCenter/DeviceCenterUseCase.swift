import Foundation

public protocol DeviceCenterUseCaseProtocol {
    func fetchUserDevices() async -> [DeviceEntity]
}

public struct DeviceCenterUseCase<Repository: DeviceCenterRepositoryProtocol>: DeviceCenterUseCaseProtocol {
    private let repository: Repository
    
    public init(deviceCenterRepository: Repository) {
        self.repository = deviceCenterRepository
    }
    
    public func fetchUserDevices() async -> [DeviceEntity] {
        await repository.fetchUserDevices()
    }
}
