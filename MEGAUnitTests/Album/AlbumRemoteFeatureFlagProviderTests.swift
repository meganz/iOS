@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import Testing

struct AlbumRemoteFeatureFlagProviderTests {
    
    @Suite("Should always return true until provider is removed")
    struct EnabledState {
        @Test("Remote flag should return correct state")
        func remoteFlag() {
            let sut = AlbumRemoteFeatureFlagProvider()
            
            #expect(sut.isPerformanceImprovementsEnabled() == true)
        }
    }
}
