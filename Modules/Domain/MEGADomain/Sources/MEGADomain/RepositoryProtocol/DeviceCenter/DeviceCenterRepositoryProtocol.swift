import Foundation

public protocol DeviceCenterRepositoryProtocol: RepositoryProtocol, Sendable {
    func fetchUserDevices() async -> [DeviceEntity]
    func fetchDeviceNames() async -> [String]
    func loadCurrentDeviceId() -> String?
}
