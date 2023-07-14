import MEGADomain

public struct MockDeviceCenterUseCase: DeviceCenterUseCaseProtocol {
    private let devices: [DeviceEntity]
    
    public init(devices: [DeviceEntity] = [] ) {
        self.devices = devices
    }
    
    public func fetchUserDevices() async -> [DeviceEntity] {
        devices
    }
    
    public func loadCurrentDeviceId() -> String? { "" }
}
