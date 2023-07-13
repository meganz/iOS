
// MARK: - Use case protocol
public protocol AccountUseCaseProtocol {
    var currentUserHandle: HandleEntity? { get }
    func currentUser() async -> UserEntity?
    var isGuest: Bool { get }
    func isLoggedIn() -> Bool
    func contacts() -> [UserEntity]
    func totalNodesCount() -> UInt
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void)
    func upgradeSecurity() async throws -> Bool
    var currentAccountDetails: AccountDetailsEntity? { get }
    func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity
}

// MARK: - Use case implementation
public struct AccountUseCase<T: AccountRepositoryProtocol>: AccountUseCaseProtocol {
    
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public var currentUserHandle: HandleEntity? {
        repository.currentUserHandle
    }
    
    public func currentUser() async -> UserEntity? {
        await repository.currentUser()
    }
    
    public var isGuest: Bool {
        repository.isGuest
    }
    
    public func isLoggedIn() -> Bool {
        repository.isLoggedIn()
    }
    
    public func contacts() -> [UserEntity] {
        repository.contacts()
    }
    
    public func totalNodesCount() -> UInt {
        return repository.totalNodesCount()
    }
    
    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        repository.getMyChatFilesFolder(completion: completion)
    }
    
    public var currentAccountDetails: AccountDetailsEntity? {
        repository.currentAccountDetails
    }
    
    public func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity {
        try await repository.refreshCurrentAccountDetails()
    }
    
    public func upgradeSecurity() async throws -> Bool {
        try await repository.upgradeSecurity()
    }
}
