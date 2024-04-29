import Foundation

// MARK: - Use case protocol
public protocol AccountUseCaseProtocol {
    // User authentication status and identifiers
    var currentUserHandle: HandleEntity? { get }
    var isGuest: Bool { get }
    var isNewAccount: Bool { get }
    var myEmail: String? { get }

    // Account characteristics
    var accountCreationDate: Date? { get }
    var currentAccountDetails: AccountDetailsEntity? { get }
    var bandwidthOverquotaDelay: Int64 { get }
    var isOverQuota: Bool { get }
    var isMasterBusinessAccount: Bool { get }
    var isSmsAllowed: Bool { get }
    var isAchievementsEnabled: Bool { get }
    
    // User and session management
    func currentUser() async -> UserEntity?
    func isLoggedIn() -> Bool
    func isAccountType(_ type: AccountTypeEntity) -> Bool

    // Account operations
    func contacts() -> [UserEntity]
    func totalNodesCount() -> UInt64
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void)
    func upgradeSecurity() async throws -> Bool
    func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity
    func getMiscFlags() async throws
    func sessionTransferURL(path: String) async throws -> URL
    func multiFactorAuthCheck(email: String) async throws -> Bool
}

extension AccountUseCaseProtocol {
    public var isFreeTierUser: Bool {
        currentAccountDetails?.proLevel == .free
    }
}

// MARK: - Use case implementation
public struct AccountUseCase<T: AccountRepositoryProtocol>: AccountUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }

    // MARK: - User authentication status and identifiers
    public var currentUserHandle: HandleEntity? {
        repository.currentUserHandle
    }

    public var isGuest: Bool {
        repository.isGuest
    }

    public var isNewAccount: Bool {
        repository.isNewAccount
    }

    public var myEmail: String? {
        repository.myEmail
    }
    
    // MARK: - Account characteristics
    public var accountCreationDate: Date? {
        repository.accountCreationDate
    }

    public var currentAccountDetails: AccountDetailsEntity? {
        repository.currentAccountDetails
    }

    public var bandwidthOverquotaDelay: Int64 {
        repository.bandwidthOverquotaDelay
    }

    public var isOverQuota: Bool {
        guard let accountDetails = currentAccountDetails else { return false }
        return accountDetails.storageUsed > accountDetails.storageMax
    }

    public var isMasterBusinessAccount: Bool {
        repository.isMasterBusinessAccount
    }
    
    public var isSmsAllowed: Bool {
        repository.isSMSAllowed
    }
    
    public var isAchievementsEnabled: Bool {
        repository.isAchievementsEnabled
    }

    // MARK: - User and session management
    public func currentUser() async -> UserEntity? {
        await repository.currentUser()
    }
    
    public func isLoggedIn() -> Bool {
        repository.isLoggedIn()
    }
    
    public func isAccountType(_ type: AccountTypeEntity) -> Bool {
        repository.isAccountType(type)
    }

    // MARK: - Account operations
    public func contacts() -> [UserEntity] {
        repository.contacts()
    }
    
    public func totalNodesCount() -> UInt64 {
        return repository.totalNodesCount()
    }

    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        repository.getMyChatFilesFolder(completion: completion)
    }
    
    public func upgradeSecurity() async throws -> Bool {
        try await repository.upgradeSecurity()
    }

    public func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity {
        try await repository.refreshCurrentAccountDetails()
    }
    
    public func getMiscFlags() async throws {
        try await repository.getMiscFlags()
    }
    
    public func sessionTransferURL(path: String) async throws -> URL {
        try await repository.sessionTransferURL(path: path)
    }
    
    public func multiFactorAuthCheck(email: String) async throws -> Bool {
        try await repository.multiFactorAuthCheck(email: email)
    }
}
