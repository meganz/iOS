@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import Testing

struct AlbumRemoteFeatureFlagProviderTests {
    
    @Suite("Call to check enabled state")
    struct EnabledState {
        @Test("Local flag is off should return false")
        func localFlagOff() async throws {
            let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: false])
            let sut = AlbumRemoteFeatureFlagProviderTests.makeSUT(
                featureFlagProvider: featureFlagProvider)
            
            #expect(sut.isPerformanceImprovementsEnabled() == false)
        }
        
        @Test("Local flag is off should return remote flag status",
              arguments: [true, false])
        func remoteFlag(isRemoteEnabled: Bool) async throws {
            let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: true])
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.albumPerformanceImprovements: isRemoteEnabled])
            let sut = AlbumRemoteFeatureFlagProviderTests.makeSUT(
                featureFlagProvider: featureFlagProvider,
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            
            #expect(sut.isPerformanceImprovementsEnabled() == isRemoteEnabled)
        }
    }
    
    private static func makeSUT(
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase()
    ) -> AlbumRemoteFeatureFlagProvider {
        AlbumRemoteFeatureFlagProvider(
            featureFlagProvider: featureFlagProvider,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
    }
}
