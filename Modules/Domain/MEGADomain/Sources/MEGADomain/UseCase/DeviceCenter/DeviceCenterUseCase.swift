import Foundation

public protocol DeviceCenterUseCaseProtocol: Sendable {
    func fetchUserDevices() async -> [DeviceEntity]
    func fetchDeviceNames() async -> [String]
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
    
    public func fetchDeviceNames() async -> [String] {
        await repository.fetchDeviceNames()
    }
    
    public func loadCurrentDeviceId() -> String? {
        repository.loadCurrentDeviceId()
    }
}
