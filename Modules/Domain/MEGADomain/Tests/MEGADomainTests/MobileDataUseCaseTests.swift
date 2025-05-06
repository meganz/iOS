import MEGADomain
import MEGADomainMock
import MEGAPreference
import Testing

@Suite("MobileDataUseCaseTests")
struct MobileDataUseCaseTests {
    @Test("Should return correct value based on preference", arguments: [false, true])
    func isMobileDataForPreviewingEnabled(for preferenceValue: Bool) {
        let sut = makeSUT(preferenceValues: [PreferenceKeyEntity.useMobileDataForPreviewingOriginalPhoto.rawValue: preferenceValue])

        #expect(
            sut.isMobileDataForPreviewingEnabled() == preferenceValue,
            "Expected \(preferenceValue) but got \(sut.isMobileDataForPreviewingEnabled())"
        )
    }
    
    @Test("Should update the preference value correctly", arguments: [true, false])
    func updateMobileDataForPreviewingEnabled(for newValue: Bool) {
        let sut = makeSUT(preferenceValues: [PreferenceKeyEntity.useMobileDataForPreviewingOriginalPhoto.rawValue: !newValue])
        
        sut.updateMobileDataForPreviewingEnabled(newValue)
        
        #expect(
            sut.isMobileDataForPreviewingEnabled() == newValue,
            "Expected \(newValue) but got \(sut.isMobileDataForPreviewingEnabled())"
        )
    }
    
    private func makeSUT(preferenceValues: [PreferenceKeyEntity.RawValue: Bool]) -> MobileDataUseCase {
        let preference = MockPreferenceUseCase(dict: preferenceValues)
        return MobileDataUseCase(preferenceUseCase: preference)
    }
}
