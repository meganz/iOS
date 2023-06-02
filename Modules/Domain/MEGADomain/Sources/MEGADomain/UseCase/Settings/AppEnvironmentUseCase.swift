
public protocol AppEnvironmentUseCaseProtocol {
    var configuration: AppConfigurationEntity { get }
    func config(_ configuration: AppConfigurationEntity)
}

public final class AppEnvironmentUseCase: AppEnvironmentUseCaseProtocol {
    public static let shared = AppEnvironmentUseCase()
    
    public private(set) var configuration: AppConfigurationEntity
    
    private init(configuration: AppConfigurationEntity = .production) {
        self.configuration = configuration
    }
    
    public func config(_ configuration: AppConfigurationEntity) {
        self.configuration = configuration
    }
}
