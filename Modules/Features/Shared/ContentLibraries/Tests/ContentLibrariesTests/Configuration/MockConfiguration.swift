import ContentLibraries
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomainMock

extension ContentLibraries.Configuration {
    static func mockConfiguration(
        isAlbumPerformanceImprovementsEnabled: Bool = false,
        featureFlags: [FeatureFlagKey: Bool] = [:]
    ) -> Self {
        self.init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            featureFlagProvider: MockFeatureFlagProvider(list: featureFlags),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { isAlbumPerformanceImprovementsEnabled })
    }
}
