
// MARK: - Use case protocol
protocol AccountUseCaseProtocol {
    func totalNodesCount() -> UInt
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void)
}

// MARK: - Use case implementation
struct AccountUseCase: AccountUseCaseProtocol {
    
    private let repository: AccountRepositoryProtocol
    
    init(repository: AccountRepositoryProtocol) {
        self.repository = repository
    }
    
    func totalNodesCount() -> UInt {
        return repository.totalNodesCount()
    }
    
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        repository.getMyChatFilesFolder(completion: completion)
    }
}
