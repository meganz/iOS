@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("DeviceStorageCheckerTests")
struct DeviceStorageCheckerTests {
    @Test("Reports a shortfall with both figures the warning quotes")
    func reportsShortfallWithBothFigures() async {
        let sut = makeSUT(requirementResult: .success(.init(requiredBytes: 100, availableBytes: 99)))

        #expect(await sut.verdict(forAdditionalBytes: 100) == .doesNotFit(requiredBytes: 100, availableBytes: 99))
    }

    @Test("Fits once the device has exactly as much room as the operation needs")
    func fitsWhenCapacityMeetsTheRequirement() async {
        let sut = makeSUT(requirementResult: .success(.init(requiredBytes: 100, availableBytes: 100)))

        #expect(await sut.verdict(forAdditionalBytes: 100) == .fits)
    }

    @Test("Fits when the available capacity cannot be read, so the transfer is never blocked by a check that could not run")
    func fitsWhenCapacityIsUnknown() async {
        let sut = makeSUT(requirementResult: .failure(.availableCapacityUnknown))

        #expect(await sut.verdict(forAdditionalBytes: 100) == .fits)
    }

    private func makeSUT(
        requirementResult: Result<DeviceStorageRequirementEntity, DeviceStorageErrorEntity>
    ) -> DeviceStorageChecker {
        .init(deviceStorageUseCase: MockDeviceStorageUseCase(requirementResult: requirementResult))
    }
}
