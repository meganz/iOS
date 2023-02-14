
// MARK: - Use case protocol
public protocol AccountUseCaseProtocol {
    func totalNodesCount() -> UInt
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void)
    func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void)
    func upgradeSecurity() async throws -> Bool
}

// MARK: - Use case implementation
public struct AccountUseCase<T: AccountRepositoryProtocol>: AccountUseCaseProtocol {
    
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func totalNodesCount() -> UInt {
        return repository.totalNodesCount()
    }
    
    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        repository.getMyChatFilesFolder(completion: completion)
    }
    
    public func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void) {
        repository.getAccountDetails(completion: completion)
    }
    
    public func upgradeSecurity() async throws -> Bool {
        try await repository.upgradeSecurity()
    }
}
