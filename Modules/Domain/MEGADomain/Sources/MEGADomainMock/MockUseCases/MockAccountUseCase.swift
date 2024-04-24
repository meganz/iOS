import Foundation
import MEGADomain

public struct MockAccountUseCase: AccountUseCaseProtocol {
    private let totalNodesCountVariable: UInt64
    private let getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>)
    private let accountDetailsResult: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>)
    private let miscFlagsResult: Result<Void, AccountErrorEntity>
    private let sessionTransferURLResult: Result<URL, AccountErrorEntity>
    private let isUpgradeSecuritySuccess: Bool
    private let multiFactorAuthCheckResult: Bool
    private var multiFactorAuthCheckDelay: TimeInterval
    private let _bandwidthOverquotaDelay: Int64
    private let _currentUser: UserEntity?
    private let _isGuest: Bool
    private let _isNewAccount: Bool
    private let _accountCreationDate: Date?
    private let _isLoggedIn: Bool
    private let _contacts: [UserEntity]
    private let _currentAccountDetails: AccountDetailsEntity?
    private let _isOverQuota: Bool
    private let _email: String?
    private let _isMasterBusinessAccount: Bool
    private let smsState: SMSStateEntity
    
    public init(
        currentUser: UserEntity? = UserEntity(handle: .invalid),
        isGuest: Bool = false,
        isNewAccount: Bool = false,
        isLoggedIn: Bool = true,
        accountCreationDate: Date? = nil,
        contacts: [UserEntity] = [],
        totalNodesCountVariable: UInt64 = 0,
        getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity> = .failure(.nodeNotFound),
        currentAccountDetails: AccountDetailsEntity? = nil,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        miscFlagsResult: Result<Void, AccountErrorEntity> = .failure(.generic),
        sessionTransferURLResult: Result<URL, AccountErrorEntity> = .failure(.generic),
        isUpgradeSecuritySuccess: Bool = false,
        bandwidthOverquotaDelay: Int64 = 0,
        isOverQuota: Bool = false,
        email: String? = nil,
        isMasterBusinessAccount: Bool = false,
        smsState: SMSStateEntity = .notAllowed,
        multiFactorAuthCheckResult: Bool = false,
        multiFactorAuthCheckDelay: TimeInterval = 0
    ) {
        _currentUser = currentUser
        _isGuest = isGuest
        _isNewAccount = isNewAccount
        _isLoggedIn = isLoggedIn
        _accountCreationDate = accountCreationDate
        _contacts = contacts
        _currentAccountDetails = currentAccountDetails
        _bandwidthOverquotaDelay = bandwidthOverquotaDelay
        _isOverQuota = isOverQuota
        _email = email
        _isMasterBusinessAccount = isMasterBusinessAccount
        self.smsState = smsState
        self.totalNodesCountVariable = totalNodesCountVariable
        self.getMyChatFilesFolderResult = getMyChatFilesFolderResult
        self.accountDetailsResult = accountDetailsResult
        self.miscFlagsResult = miscFlagsResult
        self.sessionTransferURLResult = sessionTransferURLResult
        self.isUpgradeSecuritySuccess = isUpgradeSecuritySuccess
        self.multiFactorAuthCheckResult = multiFactorAuthCheckResult
        self.multiFactorAuthCheckDelay = multiFactorAuthCheckDelay
    }
    
    // MARK: - User authentication status and identifiers
    public var currentUserHandle: HandleEntity? {
        _currentUser?.handle
    }
    
    public var isGuest: Bool {
        _isGuest
    }
    
    public var isNewAccount: Bool {
        _isNewAccount
    }
    
    public var myEmail: String? {
        _email
    }
    
    // MARK: - Account characteristics
    public var accountCreationDate: Date? {
        _accountCreationDate
    }
    
    public var currentAccountDetails: AccountDetailsEntity? {
        _currentAccountDetails
    }
    
    public var bandwidthOverquotaDelay: Int64 {
        _bandwidthOverquotaDelay
    }
    
    public var isOverQuota: Bool {
        _isOverQuota
    }
    
    public var isMasterBusinessAccount: Bool {
        _isMasterBusinessAccount
    }
    
    public var isSmsAllowed: Bool {
        smsState == .optInAndUnblock
    }
    
    // MARK: - User and session management
    public func currentUser() async -> UserEntity? {
        _currentUser
    }
    
    public func isLoggedIn() -> Bool {
        _isLoggedIn
    }
    
    public func isAccountType(_ type: AccountTypeEntity) -> Bool {
        _currentAccountDetails?.proLevel == type
    }
    
    // MARK: - Account operations
    public func contacts() -> [UserEntity] {
        _contacts
    }
    
    public func totalNodesCount() -> UInt64 {
        totalNodesCountVariable
    }
    
    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
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
    
    public func multiFactorAuthCheck(email: String) async throws -> Bool {
        if multiFactorAuthCheckDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(multiFactorAuthCheckDelay * 1_000_000_000))
        }
        
        return multiFactorAuthCheckResult
    }
}
