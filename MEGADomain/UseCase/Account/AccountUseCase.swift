
// MARK: - Use case protocol
protocol AccountUseCaseProtocol {
    func totalNodesCount() -> UInt
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void)
    func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void)
}

// MARK: - Use case implementation
struct AccountUseCase<T: AccountRepositoryProtocol>: AccountUseCaseProtocol {
    
    private let repository: T
    
    init(repository: T) {
        self.repository = repository
    }
    
    func totalNodesCount() -> UInt {
        return repository.totalNodesCount()
    }
    
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        repository.getMyChatFilesFolder(completion: completion)
    }
    
    func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void) {
        repository.getAccountDetails(completion: completion)
    }
}
