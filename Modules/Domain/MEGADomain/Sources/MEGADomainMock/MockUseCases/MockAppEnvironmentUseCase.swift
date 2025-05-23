import MEGADomain
import MEGAInfrastructure

public final class MockAppEnvironmentUseCase: AppEnvironmentUseCaseProtocol, @unchecked Sendable {
    public var configuration: AppConfigurationEntity
    
    public init(configuration: AppConfigurationEntity = .debug) {
        self.configuration = configuration
    }
    
    public func config(_ configuration: AppConfigurationEntity) {
        self.configuration = configuration
    }
}
