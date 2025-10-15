public protocol DeviceUseCaseProtocol: Sendable {
    func fetchDeviceName(_ deviceId: String?) async throws -> String?
    func fetchCurrentDeviceName() async throws -> String?
    func renameDevice(_ deviceId: String?, newName: String) async throws
    func renameCurrentDevice(newName: String) async throws
}

public struct DeviceUseCase<T: DeviceRepositoryProtocol>: DeviceUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func fetchDeviceName(_ deviceId: String?) async throws -> String? {
        try await repository.fetchDeviceName(deviceId)
    }
    
    public func fetchCurrentDeviceName() async throws -> String? {
        try await repository.fetchDeviceName(nil)
    }
    
    public func renameDevice(_ deviceId: String?, newName: String) async throws {
        try await repository.renameDevice(
            deviceId,
            newName: newName
        )
    }
    
    public func renameCurrentDevice(newName: String) async throws {
        try await repository.renameDevice(
            nil,
            newName: newName
        )
    }
}
