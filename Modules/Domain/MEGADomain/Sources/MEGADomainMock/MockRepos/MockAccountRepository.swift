import Combine
import Foundation
import MEGADomain
import MEGASwift

public final class MockAccountRepository: AccountRepositoryProtocol, @unchecked Sendable {
    // MARK: - User Authentication Details
    let currentUser: UserEntity?
    public let isGuest: Bool
    private let _isLoggedIn: Bool
    private let _myEmail: String?
    private let _isNewAccount: Bool
    private let _isMasterBusinessAccount: Bool
    private let _isExpiredAccount: Bool
    private let _isInGracePeriod: Bool
    private let _isBilledProPlan: Bool
    private let _hasMultipleBilledProPlan: Bool
    private let accountType: AccountTypeEntity

    // MARK: - Account Characteristics
    private let _currentAccountDetails: AccountDetailsEntity?
    private let _accountCreationDate: Date?
    private let _bandwidthOverquotaDelay: Int64
    private let nodesCount: UInt64
    private let _contacts: [UserEntity]
    private let _isSmsAllowed: Bool
    private let _isAchievementsEnabled: Bool
    private let _plans: [PlanEntity]
    private let _currentProPlan: AccountPlanEntity?
    private let _currentSubscription: AccountSubscriptionEntity?

    // MARK: - Result Handlers
    private let getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity>
    private let accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity>
    private let miscFlagsResult: Result<Void, AccountErrorEntity>
    private let sessionTransferURLResult: Result<URL, AccountErrorEntity>
    private let multiFactorAuthCheckResult: Result<Bool, AccountErrorEntity>
    private let isUpgradeSecuritySuccess: Bool
    
    // MARK: - Management of Contacts and Alerts
    private let contactsRequestsCount: Int
    private let unseenUserAlertsCount: UInt

    // MARK: - Delegate Management Counters
    @Atomic public var registerMEGARequestDelegateCalled = 0
    @Atomic public var deRegisterMEGARequestDelegateCalled = 0
    @Atomic public var registerMEGAGlobalDelegateCalled = 0
    @Atomic public var deRegisterMEGAGlobalDelegateCalled = 0

    // MARK: - Publishers
    public let requestResultPublisher: AnyPublisher<Result<AccountRequestEntity, Error>, Never>
    public let contactRequestPublisher: AnyPublisher<[ContactRequestEntity], Never>
    public let userAlertUpdatePublisher: AnyPublisher<[UserAlertEntity], Never>
    
    // MARK: - Node Sizes
    public let rootStorage: Int64
    public let rubbishBinStorage: Int64
    public let incomingSharesStorage: Int64
    public let backupStorage: Int64

    // MARK: - Initializer
    public init(
        currentUser: UserEntity? = nil,
        isGuest: Bool = false,
        isNewAccount: Bool = false,
        accountCreationDate: Date? = nil,
        myEmail: String? = nil,
        isLoggedIn: Bool = true,
        isMasterBusinessAccount: Bool = false,
        isExpiredAccount: Bool = false,
        isInGracePeriod: Bool = false,
        isBilledProPlan: Bool = false,
        hasMultipleBilledProPlan: Bool = false,
        isAchievementsEnabled: Bool = false,
        plans: [PlanEntity] = [],
        isSmsAllowed: Bool = false,
        contacts: [UserEntity] = [],
        nodesCount: UInt64 = 0,
        contactsRequestsCount: Int = 0,
        unseenUserAlertsCount: UInt = 0,
        getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity> = .failure(.nodeNotFound),
        currentAccountDetails: AccountDetailsEntity? = nil,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        miscFlagsResult: Result<Void, AccountErrorEntity> = .failure(.generic),
        sessionTransferURLResult: Result<URL, AccountErrorEntity> = .failure(.generic),
        multiFactorAuthCheckResult: Result<Bool, AccountErrorEntity> = .failure(.generic),
        requestResultPublisher: AnyPublisher<Result<AccountRequestEntity, Error>, Never> = Empty().eraseToAnyPublisher(),
        contactRequestPublisher: AnyPublisher<[ContactRequestEntity], Never> = Empty().eraseToAnyPublisher(),
        userAlertUpdatePublisher: AnyPublisher<[UserAlertEntity], Never> = Empty().eraseToAnyPublisher(),
        isUpgradeSecuritySuccess: Bool = false,
        bandwidthOverquotaDelay: Int64 = 0,
        accountType: AccountTypeEntity = .free,
        rootStorage: Int64 = 0,
        rubbishBinStorage: Int64 = 0,
        incomingSharesStorage: Int64 = 0,
        backupStorage: Int64 = 0,
        currentProPlan: AccountPlanEntity? = nil,
        currentSubscription: AccountSubscriptionEntity? = nil
    ) {
        self.currentUser = currentUser
        self.isGuest = isGuest
        _isLoggedIn = isLoggedIn
        _myEmail = myEmail
        _isNewAccount = isNewAccount
        _isMasterBusinessAccount = isMasterBusinessAccount
        _isExpiredAccount = isExpiredAccount
        _isInGracePeriod = isInGracePeriod
        _isBilledProPlan = isBilledProPlan
        _hasMultipleBilledProPlan = hasMultipleBilledProPlan
        _isAchievementsEnabled = isAchievementsEnabled
        _plans = plans
        _currentProPlan = currentProPlan
        _currentSubscription = currentSubscription
        _accountCreationDate = accountCreationDate
        _isSmsAllowed = isSmsAllowed
        _contacts = contacts
        _currentAccountDetails = currentAccountDetails
        _bandwidthOverquotaDelay = bandwidthOverquotaDelay
        self.nodesCount = nodesCount
        self.contactsRequestsCount = contactsRequestsCount
        self.unseenUserAlertsCount = unseenUserAlertsCount
        self.getMyChatFilesFolderResult = getMyChatFilesFolderResult
        self.accountDetailsResult = accountDetailsResult
        self.miscFlagsResult = miscFlagsResult
        self.sessionTransferURLResult = sessionTransferURLResult
        self.isUpgradeSecuritySuccess = isUpgradeSecuritySuccess
        self.multiFactorAuthCheckResult = multiFactorAuthCheckResult
        self.requestResultPublisher = requestResultPublisher
        self.contactRequestPublisher = contactRequestPublisher
        self.userAlertUpdatePublisher = userAlertUpdatePublisher
        self.accountType = accountType
        self.rootStorage = rootStorage
        self.rubbishBinStorage = rubbishBinStorage
        self.incomingSharesStorage = incomingSharesStorage
        self.backupStorage = backupStorage
    }

    // MARK: - AccountRepositoryProtocol Implementation

    public var currentUserHandle: HandleEntity? {
        currentUser?.handle
    }

    public func currentUser() async -> UserEntity? {
        currentUser
    }

    public var myEmail: String? {
        _myEmail
    }

    public func isLoggedIn() -> Bool {
        _isLoggedIn
    }

    public var isMasterBusinessAccount: Bool {
        _isMasterBusinessAccount
    }
    
    public var isAchievementsEnabled: Bool {
        _isAchievementsEnabled
    }
    
    public func currentAccountPlan() async -> PlanEntity? {
        _plans.first { $0.type == _currentAccountDetails?.proLevel && $0.subscriptionCycle == _currentAccountDetails?.subscriptionCycle }
    }

    public var isNewAccount: Bool {
        _isNewAccount
    }
    
    public func isExpiredAccount() -> Bool {
        _isExpiredAccount
    }
    
    public func isInGracePeriod() -> Bool {
        _isInGracePeriod
    }
    
    public func isBilledProPlan() -> Bool {
        _isBilledProPlan
    }
    
    public func hasMultipleBilledProPlans() -> Bool {
        _hasMultipleBilledProPlan
    }
    
    public var currentProPlan: AccountPlanEntity? {
        _currentProPlan
    }
    
    public func currentSubscription() -> AccountSubscriptionEntity? {
        _currentSubscription
    }
    
    public var accountCreationDate: Date? {
        _accountCreationDate
    }

    public func contacts() -> [UserEntity] {
        _contacts
    }

    public var bandwidthOverquotaDelay: Int64 {
        _bandwidthOverquotaDelay
    }

    public func totalNodesCount() -> UInt64 {
        nodesCount
    }

    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }

    public var currentAccountDetails: AccountDetailsEntity? {
        _currentAccountDetails
    }

    public func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity {
        switch accountDetailsResult {
        case .success(let details): return details
        case .failure(let error): throw error
        }
    }

    public func upgradeSecurity() async throws -> Bool {
        isUpgradeSecuritySuccess
    }

    public func getMiscFlags() async throws {
        if case .failure(let error) = miscFlagsResult {
            throw error
        }
    }

    public func sessionTransferURL(path: String) async throws -> URL {
        switch sessionTransferURLResult {
        case .success(let url): return url
        case .failure(let error): throw error
        }
    }

    public var isSMSAllowed: Bool {
        _isSmsAllowed
    }

    public func isAccountType(_ type: AccountTypeEntity) -> Bool {
        type == accountType
    }

    public func multiFactorAuthCheck(email: String) async throws -> Bool {
        switch multiFactorAuthCheckResult {
        case .success(let isMultifactorAuth): return isMultifactorAuth
        case .failure(let error): throw error
        }
    }

    public func incomingContactsRequestsCount() -> Int {
        contactsRequestsCount
    }

    public func relevantUnseenUserAlertsCount() -> UInt {
        unseenUserAlertsCount
    }

    public func registerMEGARequestDelegate() async {
        $registerMEGARequestDelegateCalled.mutate { $0 += 1 }
    }

    public func deRegisterMEGARequestDelegate() {
        $deRegisterMEGARequestDelegateCalled.mutate { $0 += 1 }
    }

    public func registerMEGAGlobalDelegate() async {
        $registerMEGAGlobalDelegateCalled.mutate { $0  += 1 }
    }

    public func deRegisterMEGAGlobalDelegate() async {
        $deRegisterMEGAGlobalDelegateCalled.mutate { $0 += 1 }
    }

    public func rootStorageUsed() -> Int64 {
        rootStorage
    }
    
    public func rubbishBinStorageUsed() -> Int64 {
        rubbishBinStorage
    }
    
    public func incomingSharesStorageUsed() -> Int64 {
        incomingSharesStorage
    }
    
    public func backupStorageUsed() async throws -> Int64 {
        backupStorage
    }
}
