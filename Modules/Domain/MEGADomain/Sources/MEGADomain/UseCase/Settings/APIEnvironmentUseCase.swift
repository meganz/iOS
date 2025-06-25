public protocol APIEnvironmentUseCaseProtocol: Sendable {
    mutating func changeAPIURL(_ environment: APIEnvironmentEntity)
}

public struct APIEnvironmentUseCase: APIEnvironmentUseCaseProtocol {
    private var apiEnvironmentRepository: any APIEnvironmentRepositoryProtocol
    private var chatURLRepository: any ChatURLRespositoryProtocol
    
    public init(apiEnvironmentRepository: some APIEnvironmentRepositoryProtocol, chatURLRepository: some ChatURLRespositoryProtocol) {
        self.apiEnvironmentRepository = apiEnvironmentRepository
        self.chatURLRepository = chatURLRepository
    }
    
    public mutating func changeAPIURL(_ environment: APIEnvironmentEntity) {
        apiEnvironmentRepository.changeAPIURL(environment) {
            chatURLRepository.refreshUrls()
        }
    }
}
