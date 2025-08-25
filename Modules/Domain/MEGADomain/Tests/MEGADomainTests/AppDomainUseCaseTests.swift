import MEGADomain
import MEGADomainMock
import MEGAPreference
import Testing

struct AppDomainUseCaseTests {

    @Test func testDomainName_whenFeatureToggleIsOff_shouldReturnMEGADotNZ() {
        let sut = AppDomainUseCase(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(),
            isLocalFeatureFlagEnabled: false
        )

        #expect(sut.domainName == "mega.nz")
    }

    @Test func testDomainName_whenLocalFeatureToggleIsOnAndRemoteFeatureToggleIsOff_shouldReturnMEGADotNZ() {
        let sut = AppDomainUseCase(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.dotAppDomainExtension: false]),
            isLocalFeatureFlagEnabled: true
        )

        #expect(sut.domainName == "mega.nz")
    }

    @Test func testDomainName_whenFeatureToggleIsOn_shouldReturnMEGADotApp() {
        let sut = AppDomainUseCase(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.dotAppDomainExtension: true]),
            isLocalFeatureFlagEnabled: true
        )

        #expect(sut.domainName == "mega.app")
    }
}
