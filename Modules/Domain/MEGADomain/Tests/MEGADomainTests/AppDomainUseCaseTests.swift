import MEGADomain
import MEGADomainMock
import MEGAPreference
import Testing

struct AppDomainUseCaseTests {

    @Test func testDomainName_whenFeatureToggleIsOff_shouldReturnMEGADotNZ() {
        let preference = MockPreferenceUseCase()
        let sut = AppDomainUseCase(
            preferenceUseCase: preference,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(),
            isLocalFeatureFlagEnabled: false
        )

        #expect(sut.domainName == "mega.nz")
        #expect(preference.dict as? [String: Bool] == ["isDomainNameMEGADotApp": false])
    }

    @Test func testDomainName_whenLocalFeatureToggleIsOnAndRemoteFeatureToggleIsOff_shouldReturnMEGADotNZ() {
        let preference = MockPreferenceUseCase()
        let sut = AppDomainUseCase(
            preferenceUseCase: preference,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.dotAppDomainExtension: false]),
            isLocalFeatureFlagEnabled: true
        )

        #expect(sut.domainName == "mega.nz")
        #expect(preference.dict as? [String: Bool] == ["isDomainNameMEGADotApp": false])
    }

    @Test func testDomainName_whenFeatureToggleIsOn_shouldReturnMEGADotApp() {
        let preference = MockPreferenceUseCase()
        let sut = AppDomainUseCase(
            preferenceUseCase: preference,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.dotAppDomainExtension: true]),
            isLocalFeatureFlagEnabled: true
        )

        #expect(sut.domainName == "mega.app")
        #expect(preference.dict as? [String: Bool] == ["isDomainNameMEGADotApp": true])
    }
}
