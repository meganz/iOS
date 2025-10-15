public protocol DeviceRepositoryProtocol: RepositoryProtocol, Sendable {
    func fetchDeviceName(_ deviceId: String?) async throws -> String?
    func renameDevice(_ deviceId: String?, newName: String) async throws
}
