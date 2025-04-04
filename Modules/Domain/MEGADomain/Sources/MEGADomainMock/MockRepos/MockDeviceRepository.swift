import MEGADomain

public struct MockDeviceRepository: DeviceRepositoryProtocol, Sendable {
    public static let newRepo = MockDeviceRepository()
    private let currentDeviceName: String?
    private let deviceName: String?
    private let renameError: (any Error)?
    
    public init(
        currentDeviceName: String? = nil,
        deviceName: String? = nil,
        renameError: (any Error)? = nil
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
