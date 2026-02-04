import ContentLibraries
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomainMock

extension ContentLibraries.Configuration {
    static func mockConfiguration(
        isAlbumPerformanceImprovementsEnabled: Bool = false,
        remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(),
        featureFlags: [FeatureFlagKey: Bool] = [:]
    ) -> Self {
        self.init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            featureFlagProvider: MockFeatureFlagProvider(list: featureFlags),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { isAlbumPerformanceImprovementsEnabled })
    }
}
