import MEGASwift

public protocol AppEnvironmentUseCaseProtocol: Sendable {
    var configuration: AppConfigurationEntity { get }
    func config(_ configuration: AppConfigurationEntity)
}

public final class AppEnvironmentUseCase: AppEnvironmentUseCaseProtocol, @unchecked Sendable {
    public static let shared = AppEnvironmentUseCase()
    
    public var configuration: AppConfigurationEntity {
        _configuration
    }
   
    @Atomic
    private var _configuration: AppConfigurationEntity = .production
    
    private init(configuration: AppConfigurationEntity = .production) {
        self.$_configuration.mutate { $0 = configuration }
    }
    
    public func config(_ configuration: AppConfigurationEntity) {
        self.$_configuration.mutate { $0 = configuration }
    }
}
