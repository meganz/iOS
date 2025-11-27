import ContentLibraries
import MEGAAppPresentationMock
import MEGADomainMock

extension ContentLibraries.Configuration {
    static func mockConfiguration(isAlbumPerformanceImprovementsEnabled: Bool = false) -> Self {
        self.init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            featureFlagProvider: MockFeatureFlagProvider(list: [:]),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { isAlbumPerformanceImprovementsEnabled })
    }
}
