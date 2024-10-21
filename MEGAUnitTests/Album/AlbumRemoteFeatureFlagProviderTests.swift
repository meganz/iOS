@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class AlbumRemoteFeatureFlagProviderTests: XCTestCase {

    func testIsPerformanceImprovementsEnabled_localFlagOff_shouldReturnFalse() async {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let isEnabled = await sut.isPerformanceImprovementsEnabled()
        
        XCTAssertFalse(isEnabled)
    }

    func testIsPerformanceImprovementsEnabled_localFlagOn_shouldReturnRemoteFlagStatus() async {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: true])
        for isRemoteEnabled in [true, false] {
            
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.albumPerformanceImprovements: isRemoteEnabled])
            let sut = makeSUT(featureFlagProvider: featureFlagProvider,
                              remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            
            let isEnabled = await sut.isPerformanceImprovementsEnabled()
    
            XCTAssertEqual(isEnabled, isRemoteEnabled)
        }
    }
    
    private func makeSUT(
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase()
    ) -> AlbumRemoteFeatureFlagProvider {
        AlbumRemoteFeatureFlagProvider(
            featureFlagProvider: featureFlagProvider,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
    }
}
