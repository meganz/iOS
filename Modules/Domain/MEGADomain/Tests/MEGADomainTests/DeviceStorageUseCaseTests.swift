import MEGADomain
import MEGADomainMock
import Testing

@Suite("DeviceStorageUseCaseTests")
struct DeviceStorageUseCaseTests {
    @Test("Reports the requested bytes against the capacity the device reports")
    func reportsRequestedBytesAgainstAvailableCapacity() async throws {
        let sut = makeSUT(availableCapacity: 1_000)

        let requirement = try await sut.requirement(forAdditionalBytes: 300)

        #expect(requirement.requiredBytes == 300)
        #expect(requirement.availableBytes == 1_000)
    }

    @Test("Throws when the device will not report its available capacity")
    func throwsWhenAvailableCapacityIsUnknown() async {
        let sut = makeSUT(availableCapacity: nil)

        await #expect(throws: DeviceStorageErrorEntity.availableCapacityUnknown) {
            try await sut.requirement(forAdditionalBytes: 100)
        }
    }

    @Test(
        "Is satisfied only when the device has at least as much room as the operation needs",
        arguments: [
            (required: UInt64(100), available: UInt64(99), isSatisfied: false),
            (required: UInt64(100), available: UInt64(100), isSatisfied: true),
            (required: UInt64(100), available: UInt64(101), isSatisfied: true),
            (required: UInt64(0), available: UInt64(0), isSatisfied: true)
        ]
    )
    func isSatisfiedComparesRequiredAgainstAvailable(
        required: UInt64,
        available: UInt64,
        isSatisfied: Bool
    ) async throws {
        let sut = makeSUT(availableCapacity: available)

        let requirement = try await sut.requirement(forAdditionalBytes: required)

        #expect(requirement.isSatisfied == isSatisfied)
    }

    private func makeSUT(availableCapacity: UInt64?) -> DeviceStorageUseCase<MockDeviceStorageRepository> {
        DeviceStorageUseCase(
            deviceStorageRepository: MockDeviceStorageRepository(availableCapacity: availableCapacity)
        )
    }
}
