import ContentLibraries
import MEGADomainMock

extension ContentLibraries.Configuration {
    static func mockConfiguration(isAlbumPerformanceImprovementsEnabled: Bool = false) -> Self {
        self.init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { isAlbumPerformanceImprovementsEnabled })
    }
}
