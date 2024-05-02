public protocol DeviceRepositoryProtocol: RepositoryProtocol {
    func fetchDeviceName(_ deviceId: String?) async throws -> String?
    func renameDevice(_ deviceId: String?, newName: String) async throws
}
