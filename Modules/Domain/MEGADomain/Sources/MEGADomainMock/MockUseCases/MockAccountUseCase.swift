import MEGADomain

public struct MockAccountUseCase: AccountUseCaseProtocol {
    private let totalNodesCountVariable: UInt
    private let getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>)
    private let accountDetailsResult: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>)
    private let isUpgradeSecuritySuccess: Bool
    private let _currentUser: UserEntity?
    private let _isGuest: Bool
    private let _isLoggedIn: Bool
    private let _contacts: [UserEntity]
    private let _currentAccountDetails: AccountDetailsEntity?
    
    public init(currentUser: UserEntity? = UserEntity(handle: 1),
                isGuest: Bool = false,
                isLoggedIn: Bool = true,
                contacts: [UserEntity] = [],
                totalNodesCountVariable: UInt = 0,
                getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity> = .failure(.nodeNotFound),
                currentAccountDetails: AccountDetailsEntity? = nil,
                accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
                isUpgradeSecuritySuccess: Bool = false) {
        _currentUser = currentUser
        _isGuest = isGuest
        _isLoggedIn = isLoggedIn
        _contacts = contacts
        _currentAccountDetails = currentAccountDetails
        self.totalNodesCountVariable = totalNodesCountVariable
        self.getMyChatFilesFolderResult = getMyChatFilesFolderResult
        self.accountDetailsResult = accountDetailsResult
        self.isUpgradeSecuritySuccess = isUpgradeSecuritySuccess
    }
    
    public var currentUserHandle: HandleEntity? {
        _currentUser?.handle
    }
    
    public func currentUser() async -> UserEntity? {
        _currentUser
    }
    
    public var isGuest: Bool {
        _isGuest
    }
    
    public func isLoggedIn() -> Bool {
        _isLoggedIn
    }
    
    public func contacts() -> [UserEntity] {
        _contacts
    }
    
    public func totalNodesCount() -> UInt {
        totalNodesCountVariable
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
}
