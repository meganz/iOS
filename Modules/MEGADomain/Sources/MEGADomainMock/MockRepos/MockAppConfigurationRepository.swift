import MEGADomain

public struct MockAppConfigurationRepository: AppConfigurationRepositoryProtocol {
    public static var newRepo: MockAppConfigurationRepository {
        MockAppConfigurationRepository(configuration: .debug)
    }
    
    public var configuration: AppConfigurationEntity
    public init(configuration: AppConfigurationEntity) {
        self.configuration = configuration
    }
}
