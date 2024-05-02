import MEGADomain

public struct MockDeviceRepository: DeviceRepositoryProtocol {
    public static var newRepo = MockDeviceRepository()
    private let currentDeviceName: String?
    private let deviceName: String?
    private let renameError: Error?
    
    public init(
        currentDeviceName: String? = nil,
        deviceName: String? = nil,
        renameError: Error? = nil
    ) {
        self.currentDeviceName = currentDeviceName
        self.deviceName = deviceName
        self.renameError = renameError
    }
    
    public func fetchDeviceName(_ deviceId: String?) async throws -> String? {
        deviceName ?? currentDeviceName
    }
    
    public func renameDevice(_ deviceId: String?, newName: String) async throws {
        if let renameError {
            throw renameError
        }
    }
}
