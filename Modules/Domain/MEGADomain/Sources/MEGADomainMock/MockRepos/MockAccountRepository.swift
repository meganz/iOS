import Combine
import Foundation
import MEGADomain

public final class MockAccountRepository: AccountRepositoryProtocol {
    // MARK: - User Authentication Details
    let currentUser: UserEntity?
    public let isGuest: Bool
    private let _isLoggedIn: Bool
    private let _myEmail: String?
    private let _isNewAccount: Bool
    private let _isMasterBusinessAccount: Bool

    // MARK: - Account Characteristics
    private let _currentAccountDetails: AccountDetailsEntity?
    private let _accountCreationDate: Date?
    private let _bandwidthOverquotaDelay: Int64
    private let nodesCount: UInt64
    private let _contacts: [UserEntity]
    private let _isSmsAllowed: Bool

    // MARK: - Result Handlers
    private let getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity>
    private let accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity>
    private let miscFlagsResult: Result<Void, AccountErrorEntity>
    private let sessionTransferURLResult: Result<URL, AccountErrorEntity>
    private let multiFactorAuthCheckResult: Result<Bool, AccountErrorEntity>
    private let isUpgradeSecuritySuccess: Bool
    private let isAccountTypeResult: Bool
    
    // MARK: - Management of Contacts and Alerts
    private let contactsRequestsCount: Int
    private let unseenUserAlertsCount: UInt

    // MARK: - Delegate Management Counters
    public var registerMEGARequestDelegateCalled = 0
    public var deRegisterMEGARequestDelegateCalled = 0
    public var registerMEGAGlobalDelegateCalled = 0
    public var deRegisterMEGAGlobalDelegateCalled = 0

    // MARK: - Publishers
    public let requestResultPublisher: AnyPublisher<Result<AccountRequestEntity, Error>, Never>
    public let contactRequestPublisher: AnyPublisher<[ContactRequestEntity], Never>
    public let userAlertUpdatePublisher: AnyPublisher<[UserAlertEntity], Never>

    // MARK: - Initializer
    public init(
        currentUser: UserEntity? = nil,
        isGuest: Bool = false,
        isNewAccount: Bool = false,
        accountCreationDate: Date? = nil,
        isAccountTypeResult: Bool = false,
        myEmail: String? = nil,
        isLoggedIn: Bool = true,
        isMasterBusinessAccount: Bool = false,
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
        bandwidthOverquotaDelay: Int64 = 0
    ) {
        self.currentUser = currentUser
        self.isGuest = isGuest
        _isLoggedIn = isLoggedIn
        _myEmail = myEmail
        _isNewAccount = isNewAccount
        _isMasterBusinessAccount = isMasterBusinessAccount
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
        self.isAccountTypeResult = isAccountTypeResult
        self.multiFactorAuthCheckResult = multiFactorAuthCheckResult
        self.requestResultPublisher = requestResultPublisher
        self.contactRequestPublisher = contactRequestPublisher
        self.userAlertUpdatePublisher = userAlertUpdatePublisher
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

    public var isNewAccount: Bool {
        _isNewAccount
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
        isAccountTypeResult
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
        registerMEGARequestDelegateCalled += 1
    }

    public func deRegisterMEGARequestDelegate() {
        deRegisterMEGARequestDelegateCalled += 1
    }

    public func registerMEGAGlobalDelegate() async {
        registerMEGAGlobalDelegateCalled += 1
    }

    public func deRegisterMEGAGlobalDelegate() async {
        deRegisterMEGAGlobalDelegateCalled += 1
    }
}
