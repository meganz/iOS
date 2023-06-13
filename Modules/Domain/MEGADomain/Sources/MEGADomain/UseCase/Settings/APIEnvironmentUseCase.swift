
public protocol APIEnvironmentUseCaseProtocol {
    func changeAPIURL(_ environment: APIEnvironmentEntity)
}

public struct APIEnvironmentUseCase: APIEnvironmentUseCaseProtocol {
    private var repository: any APIEnvironmentRepositoryProtocol
    
    public init(repository: any APIEnvironmentRepositoryProtocol) {
        self.repository = repository
    }
    
    public func changeAPIURL(_ environment: APIEnvironmentEntity) {
        repository.changeAPIURL(environment)
    }
}
