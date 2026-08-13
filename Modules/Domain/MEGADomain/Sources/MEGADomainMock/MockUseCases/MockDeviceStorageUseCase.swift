import MEGADomain

public struct MockDeviceStorageUseCase: DeviceStorageUseCaseProtocol {
    private let requirementResult: Result<DeviceStorageRequirementEntity, DeviceStorageErrorEntity>

    public init(
        requirementResult: Result<DeviceStorageRequirementEntity, DeviceStorageErrorEntity> = .failure(.availableCapacityUnknown)
    ) {
        self.requirementResult = requirementResult
    }

    public func requirement(forAdditionalBytes bytes: UInt64) async throws -> DeviceStorageRequirementEntity {
        try requirementResult.get()
    }
}
