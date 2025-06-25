public protocol APIEnvironmentRepositoryProtocol: RepositoryProtocol, Sendable {
    mutating func changeAPIURL(_ environment: APIEnvironmentEntity, onUserSessionAvailable: () -> Void) 
}
