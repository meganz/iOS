import Combine
import Foundation
import MEGASwift

public protocol AccountRepositoryProtocol: Sendable, RepositoryProtocol {
    // User authentication status and identifiers
    var currentUserHandle: HandleEntity? { get }
    var isGuest: Bool { get }
    var isNewAccount: Bool { get }
    var myEmail: String? { get }
    var isPaidAccount: Bool { get }

    // Account characteristics
    var accountCreationDate: Date? { get }
    var currentAccountDetails: AccountDetailsEntity? { get }
    var shouldRefreshStorageStatus: Bool { get }
    var bandwidthOverquotaDelay: Int64 { get }
    var isMasterBusinessAccount: Bool { get }
    var isSMSAllowed: Bool { get }
    var isAchievementsEnabled: Bool { get }
    ///  A Boolean value indicating whether the account is paywalled.
    ///
    /// - Returns: `true` if the account is paywalled.
    var isPaywalled: Bool { get }
    func currentAccountPlan() async -> PlanEntity?
    /// Retrieves the current storage status of the user's account.
    /// - Returns: A `StorageStatusEntity` that provides the current status of the user's account storage.
    /// This property reflects whether the user's storage is under quota, approaching quota, or over quota.
    var currentStorageStatus: StorageStatusEntity { get }
    /// Indicates whether the account is Pro Flexi or Business.
    /// - Returns: A Boolean value that is `true` if the current account is a Pro Flexi or Business account,
    /// where storage limits do not apply. These accounts are charged based on actual usage and have no storage restrictions.
    /// This property can be used to avoid showing storage-related warnings or banners for these account types.
    var isUnlimitedStorageAccount: Bool { get }

    // User and session management
    func currentUser() async -> UserEntity?
    func isLoggedIn() -> Bool
    func isAccountType(_ type: AccountTypeEntity) -> Bool
    func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity
    func refreshCurrentStorageState() async throws -> StorageStatusEntity?
    func isExpiredAccount() -> Bool
    func isInGracePeriod() -> Bool
    
    /// Indicates whether account refresh monitoring is active.
    /// This checks the current value of `monitorRefreshAccountSourcePublisher` in CurrentUserSource to determine
    /// if an account refresh operation is currently being monitored.
    var isMonitoringRefreshAccount: Bool { get }
    
    /// A publisher that emits updates when account refresh monitoring starts or stops.
    /// Subscribers can observe this publisher to track the refresh state
    var monitorRefreshAccount: AnyPublisher<Bool, Never> { get }
    
    /// Refreshes the current account details while monitoring the update state.
    /// - Returns: An updated `AccountDetailsEntity` after refreshing the account details.
    /// - Throws: An error if the account refresh operation fails.
    /// This function ensures that `monitorRefreshAccountSourcePublisher` in CurrentUserSource is updated to indicate
    /// when a refresh operation is in progress `true` and when it has completed `false`.
    func refreshAccountAndMonitorUpdate() async throws -> AccountDetailsEntity

    /// Checks if the current Pro plan is associated with any subscription.
    ///
    /// This function retrieves the list of account subscriptions and the current Pro plan,
    /// then checks if the Pro plan's ID matches any of the subscription IDs to determine if
    /// the Pro plan is actively subscribed.
    ///
    /// - Returns: A Boolean value indicating whether the current Pro plan is associated with any subscription.
    func isBilledProPlan() -> Bool
    /// Checks if the user has more than one Billed Pro plan associated with their account.
    ///
    /// This function examines the user's account details to determine if there are multiple Billed Pro plans
    /// currently associated with the account.
    ///
    /// - Returns: A Boolean value indicating whether the user has more than one Billed Pro plan associated with their account.
    func hasMultipleBilledProPlans() -> Bool
    
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
    func upgradeSecurity() async throws -> Bool
    func getMiscFlags() async throws
    func sessionTransferURL(path: String) async throws -> URL
    func setAccountStorageStatus(_ status: StorageStatusEntity)
    func loadUserData() async throws
    func checkRecoveryKey(_ recoveryKey: String, link: String) async throws
    
    // Account social and notifications
    func incomingContactsRequestsCount() -> Int
    func relevantUnseenUserAlertsCount() -> UInt

    // Account events and delegates
    var onRequestFinishUpdates: AnyAsyncSequence<RequestResponseEntity> { get }
    var onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> { get }
    var onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> { get }
    var onEventsUpdates: AnyAsyncSequence<EventEntity> { get }
    var onAccountUpdates: AnyAsyncSequence<Void> { get }
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
    
    // RichLinksPreview management
    func isRichLinkPreviewEnabled() async -> Bool
    func enableRichLinkPreview(_ enabled: Bool)
}
