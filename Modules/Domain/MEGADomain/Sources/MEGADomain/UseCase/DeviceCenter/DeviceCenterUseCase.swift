import Foundation

public protocol DeviceCenterUseCaseProtocol {
    func fetchUserDevices() async -> [DeviceEntity]
    func loadCurrentDeviceId() -> String?
}

public struct DeviceCenterUseCase<Repository: DeviceCenterRepositoryProtocol>: DeviceCenterUseCaseProtocol {
    private let repository: Repository
    
    public init(deviceCenterRepository: Repository) {
        self.repository = deviceCenterRepository
    }
    
    public func fetchUserDevices() async -> [DeviceEntity] {
        await repository.fetchUserDevices()
    }
    
    public func loadCurrentDeviceId() -> String? {
        repository.loadCurrentDeviceId()
    }
}
