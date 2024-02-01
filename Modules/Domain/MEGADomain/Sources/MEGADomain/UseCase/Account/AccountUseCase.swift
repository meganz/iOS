import Foundation

// MARK: - Use case protocol
public protocol AccountUseCaseProtocol {
    var currentUserHandle: HandleEntity? { get }
    func currentUser() async -> UserEntity?
    var isGuest: Bool { get }
    var isNewAccount: Bool { get }
    var accountCreationDate: Date? { get }
    var bandwidthOverquotaDelay: Int64 { get }
    func isLoggedIn() -> Bool
    func contacts() -> [UserEntity]
    func totalNodesCount() -> UInt64
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void)
    func upgradeSecurity() async throws -> Bool
    var currentAccountDetails: AccountDetailsEntity? { get }
    var isOverQuota: Bool { get }
    func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity
    func getMiscFlags() async throws
    func sessionTransferURL(path: String) async throws -> URL
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
    
    public var isNewAccount: Bool {
        repository.isNewAccount
    }
    
    public var accountCreationDate: Date? {
        repository.accountCreationDate
    }
    
    public var bandwidthOverquotaDelay: Int64 {
        repository.bandwidthOverquotaDelay
    }
    
    public func isLoggedIn() -> Bool {
        repository.isLoggedIn()
    }
    
    public func contacts() -> [UserEntity] {
        repository.contacts()
    }
    
    public func totalNodesCount() -> UInt64 {
        return repository.totalNodesCount()
    }
    
    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        repository.getMyChatFilesFolder(completion: completion)
    }
    
    public var currentAccountDetails: AccountDetailsEntity? {
        repository.currentAccountDetails
    }

    public var isOverQuota: Bool {
        guard let accountDetails = currentAccountDetails else { return false }
        return accountDetails.storageUsed > accountDetails.storageMax
    }

    public func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity {
        try await repository.refreshCurrentAccountDetails()
    }
    
    public func upgradeSecurity() async throws -> Bool {
        try await repository.upgradeSecurity()
    }
    
    public func getMiscFlags() async throws {
        try await repository.getMiscFlags()
    }
    
    public func sessionTransferURL(path: String) async throws -> URL {
        try await repository.sessionTransferURL(path: path)
    }
}
