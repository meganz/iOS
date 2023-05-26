import MEGADomain

public struct MockAccountUseCase: AccountUseCaseProtocol {
    private let totalNodesCountVariable: UInt
    private let getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>)
    private let accountDetails: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>)
    private let isUpgradeSecuritySuccess: Bool
    private let _currentUser: UserEntity?
    private let _isGuest: Bool
    private let _isLoggedIn: Bool
    private let _contacts: [UserEntity]
    
    public init(currentUser: UserEntity? = UserEntity(handle: 1),
                isGuest: Bool = false,
                isLoggedIn: Bool = true,
                contacts: [UserEntity] = [],
                totalNodesCountVariable: UInt = 0,
                getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity> = .failure(.nodeNotFound),
                accountDetails: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
                isUpgradeSecuritySuccess: Bool = false) {
        self._currentUser = currentUser
        self._isGuest = isGuest
        self._isLoggedIn = isLoggedIn
        self._contacts = contacts
        self.totalNodesCountVariable = totalNodesCountVariable
        self.getMyChatFilesFolderResult = getMyChatFilesFolderResult
        self.accountDetails = accountDetails
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
    
    public func accountDetails() async throws -> AccountDetailsEntity {
        switch accountDetails {
        case .success(let details): return details
        case .failure(let error): throw error
        }
    }
    
    public func upgradeSecurity() async throws -> Bool {
        isUpgradeSecuritySuccess
    }
}
