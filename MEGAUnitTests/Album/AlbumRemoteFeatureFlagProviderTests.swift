@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import Testing

struct AlbumRemoteFeatureFlagProviderTests {
    
    @Suite("Call to check enabled state")
    struct EnabledState {
        @Test("Remote flag should return correct state",
              arguments: [true, false])
        func remoteFlag(isRemoteEnabled: Bool) async throws {
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.albumPerformanceImprovements: isRemoteEnabled])
            let sut = AlbumRemoteFeatureFlagProviderTests.makeSUT(
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            
            #expect(sut.isPerformanceImprovementsEnabled() == isRemoteEnabled)
        }
    }
    
    private static func makeSUT(
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase()
    ) -> AlbumRemoteFeatureFlagProvider {
        AlbumRemoteFeatureFlagProvider(
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
    }
}
