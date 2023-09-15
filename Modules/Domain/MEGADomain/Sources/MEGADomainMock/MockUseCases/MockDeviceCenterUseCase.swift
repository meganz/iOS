import MEGADomain

public struct MockDeviceCenterUseCase: DeviceCenterUseCaseProtocol {
    private let devices: [DeviceEntity]
    private let currentDeviceId: String
    
    public init(devices: [DeviceEntity] = [], currentDeviceId: String = "") {
        self.devices = devices
        self.currentDeviceId = currentDeviceId
    }
    
    public func fetchUserDevices() async -> [DeviceEntity] {
        devices
    }
    
    public func loadCurrentDeviceId() -> String? {
        currentDeviceId
    }
    
    public func fetchDeviceNames() async -> [String] {
        devices.compactMap {$0.name}
    }
}
