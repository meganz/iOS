public protocol APIEnvironmentRepositoryProtocol: RepositoryProtocol {
    mutating func changeAPIURL(_ environment: APIEnvironmentEntity, onUserSessionAvailable: () -> Void) 
}
