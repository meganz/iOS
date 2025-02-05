import MEGADomain
import MEGADomainMock
import Testing

@Suite("MobileDataUseCaseTests")
struct MobileDataUseCaseTests {
    @Test("Should return correct value based on preference", arguments: [false, true])
    func isMobileDataForPreviewingEnabled(for preferenceValue: Bool) {
        let sut = makeSUT(preferenceValues: [.useMobileDataForPreviewingOriginalPhoto: preferenceValue])

        #expect(
            sut.isMobileDataForPreviewingEnabled() == preferenceValue,
            "Expected \(preferenceValue) but got \(sut.isMobileDataForPreviewingEnabled())"
        )
    }
    
    @Test("Should update the preference value correctly", arguments: [true, false])
    func updateMobileDataForPreviewingEnabled(for newValue: Bool) {
        let sut = makeSUT(preferenceValues: [.useMobileDataForPreviewingOriginalPhoto: !newValue])
        
        sut.updateMobileDataForPreviewingEnabled(newValue)
        
        #expect(
            sut.isMobileDataForPreviewingEnabled() == newValue,
            "Expected \(newValue) but got \(sut.isMobileDataForPreviewingEnabled())"
        )
    }
    
    private func makeSUT(preferenceValues: [PreferenceKeyEntity: Bool]) -> MobileDataUseCase {
        let preference = MockPreferenceUseCase(dict: preferenceValues)
        return MobileDataUseCase(preferenceUseCase: preference)
    }
}
