public protocol DefaultLaunchDestinationRepositoryProtocol: RepositoryProtocol {
    func destination(for rawValue: String) -> LaunchDestinationEntity?
    func rawValue(for entity: LaunchDestinationEntity) -> String
}
