import MEGADomain

public struct MockDeviceStorageRepository: DeviceStorageRepositoryProtocol {
    public static var newRepo: MockDeviceStorageRepository {
        MockDeviceStorageRepository()
    }

    private let _availableCapacity: UInt64?

    public init(availableCapacity: UInt64? = nil) {
        _availableCapacity = availableCapacity
    }

    public func availableCapacity() -> UInt64? {
        _availableCapacity
    }
}
