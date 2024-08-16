import Combine
import Foundation

public protocol AccountRepositoryProtocol: Sendable {
    // User authentication status and identifiers
    var currentUserHandle: HandleEntity? { get }
    var isGuest: Bool { get }
    var isNewAccount: Bool { get }
    var myEmail: String? { get }

    // Account characteristics
    var accountCreationDate: Date? { get }
    var currentAccountDetails: AccountDetailsEntity? { get }
    var bandwidthOverquotaDelay: Int64 { get }
    var isMasterBusinessAccount: Bool { get }
    var isSMSAllowed: Bool { get }
    var isAchievementsEnabled: Bool { get }
    func currentAccountPlan() async -> PlanEntity?

    // User and session management
    func currentUser() async -> UserEntity?
    func isLoggedIn() -> Bool
    func isAccountType(_ type: AccountTypeEntity) -> Bool
    func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity
    func isExpiredAccount() -> Bool
    func isInGracePeriod() -> Bool
    /// Checks if the current Pro plan is associated with any subscription.
    ///
    /// This function retrieves the list of account subscriptions and the current Pro plan,
    /// then checks if the Pro plan's ID matches any of the subscription IDs to determine if
    /// the Pro plan is actively subscribed.
    ///
    /// - Returns: A Boolean value indicating whether the current Pro plan is associated with any subscription.
    func isBilledProPlan() -> Bool
    
    /// Retrieves the Pro plan from the current account details, if it exists.
    /// - Returns: AccountPlanEntity value if there is an existing pro plan on the list of plans. It is guaranteed
    /// that a user can only have 0 or 1 Pro plan at any given time. Therefore, this
    /// property will return either a value or nil if no Pro plan is found.
    var currentProPlan: AccountPlanEntity? { get }

    /// Retrieves the current subscription that matches the currentProPlan.
    /// - Returns: AccountSubscriptionEntity value if there is an existing billed pro plan and its subscription data is available, otherwise, nil.
    func currentSubscription() -> AccountSubscriptionEntity?
    
    // Account operations
    func contacts() -> [UserEntity]
    func totalNodesCount() -> UInt64
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void)
    func upgradeSecurity() async throws -> Bool
    func getMiscFlags() async throws
    func sessionTransferURL(path: String) async throws -> URL

    // Account social and notifications
    func incomingContactsRequestsCount() -> Int
    func relevantUnseenUserAlertsCount() -> UInt

    // Account events and delegates
    var requestResultPublisher: AnyPublisher<Result<AccountRequestEntity, Error>, Never> { get }
    var contactRequestPublisher: AnyPublisher<[ContactRequestEntity], Never> { get }
    var userAlertUpdatePublisher: AnyPublisher<[UserAlertEntity], Never> { get }
    func registerMEGARequestDelegate() async
    func deRegisterMEGARequestDelegate() async
    func registerMEGAGlobalDelegate() async
    func deRegisterMEGAGlobalDelegate() async
    func multiFactorAuthCheck(email: String) async throws -> Bool
    
    // Node sizes
    
    /// Retrieves the storage used for the root node.
    /// - Returns: The storage used for the root node in bytes.
    func rootStorageUsed() -> Int64
    
    /// Retrieves the storage used for the rubbish bin.
    /// - Returns: The storage used for the rubbish bin in bytes.
    func rubbishBinStorageUsed() -> Int64
    
    /// Retrieves the storage used for incoming shared nodes.
    /// - Returns: The storage used for incoming shares in bytes.
    func incomingSharesStorageUsed() -> Int64
    
    /// Retrieves the storage used for backups.
    /// - Returns: The storage used for backups in bytes.
    /// - Throws: FolderInfoErrorEntity.notFound if the backup root node or its folder info cannot be found.
    func backupStorageUsed() async throws -> Int64
}
