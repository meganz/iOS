import ContentLibraries
import MEGADomainMock

extension ContentLibraries.Configuration {
    static func mockConfiguration() -> Self {
        self.init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase())
    }
}
