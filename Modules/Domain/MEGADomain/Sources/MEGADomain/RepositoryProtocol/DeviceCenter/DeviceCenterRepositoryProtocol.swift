import Foundation

public protocol DeviceCenterRepositoryProtocol: RepositoryProtocol {
    func fetchUserDevices() async -> [DeviceEntity]
    func fetchDeviceNames() async -> [String]
    func loadCurrentDeviceId() -> String?
}
