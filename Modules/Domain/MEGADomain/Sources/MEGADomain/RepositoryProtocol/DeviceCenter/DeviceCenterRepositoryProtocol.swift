import Foundation

public protocol DeviceCenterRepositoryProtocol: RepositoryProtocol {
    func fetchUserDevices() async -> [DeviceEntity]
}
