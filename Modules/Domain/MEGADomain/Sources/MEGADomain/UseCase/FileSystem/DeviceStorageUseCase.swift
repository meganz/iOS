// MARK: - Use case protocol -
public protocol DeviceStorageUseCaseProtocol: Sendable {
    /// Measures a known amount of new bytes against the space the device has left.
    ///
    /// Deliberately takes a byte count rather than a set of nodes: deciding which of them actually
    /// reach the disk belongs to whoever plans the transfer, since a download skips what is already
    /// offline and an export reuses what is already cached.
    /// - Throws: `DeviceStorageErrorEntity.availableCapacityUnknown` when the free space cannot be
    ///   read, leaving the decision of whether to proceed to the caller.
    func requirement(forAdditionalBytes bytes: UInt64) async throws -> DeviceStorageRequirementEntity
}

// MARK: - Use case implementation -
public struct DeviceStorageUseCase<T: DeviceStorageRepositoryProtocol>: DeviceStorageUseCaseProtocol {
    private let deviceStorageRepository: T

    public init(deviceStorageRepository: T) {
        self.deviceStorageRepository = deviceStorageRepository
    }

    /// `async` so that reading the volume, which hits the file system, stays off the caller's actor.
    public func requirement(forAdditionalBytes bytes: UInt64) async throws -> DeviceStorageRequirementEntity {
        guard let availableBytes = deviceStorageRepository.availableCapacity() else {
            throw DeviceStorageErrorEntity.availableCapacityUnknown
        }

        return DeviceStorageRequirementEntity(requiredBytes: bytes, availableBytes: availableBytes)
    }
}
