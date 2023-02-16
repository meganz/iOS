import MEGADomain

public struct APIEnvironment {
    public var title: String
    public var environment: APIEnvironmentEntity
    
    public init(title: String, environment: APIEnvironmentEntity) {
        self.title = title
        self.environment = environment
    }
}
