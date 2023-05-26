import MEGADomain

public struct MockAPIEnvironmentUseCase: APIEnvironmentUseCaseProtocol {
    public init() {}
    
    public func changeAPIURL(_ environment: MEGADomain.APIEnvironmentEntity) {}
}
