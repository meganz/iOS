import MEGADomain
import MEGAFoundation

/// Brings the plain capacity reading in `MEGAFoundation` into the Domain layer.
///
/// Anything that just wants the number should read `DeviceStorage` directly; this exists so a use case
/// keeps depending on a protocol it owns, and so the reading can be stubbed in its tests.
public struct DeviceStorageRepository: DeviceStorageRepositoryProtocol {
    public static var newRepo: DeviceStorageRepository {
        DeviceStorageRepository(deviceStorage: .current)
    }

    private let deviceStorage: DeviceStorage

    init(deviceStorage: DeviceStorage) {
        self.deviceStorage = deviceStorage
    }

    public func availableCapacity() -> UInt64? {
        deviceStorage.availableCapacity()
    }
}
