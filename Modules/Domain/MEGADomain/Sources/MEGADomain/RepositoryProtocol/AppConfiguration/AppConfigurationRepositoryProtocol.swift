public protocol AppConfigurationRepositoryProtocol: RepositoryProtocol {
    var configuration: AppConfigurationEntity { get }
}
