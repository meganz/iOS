import MEGADomain

public struct MockAccountRepository: AccountRepositoryProtocol {
    private let nodesCount: UInt
    private let getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>)
    private let accountDetails: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>)
    private let isUpgradeSecuritySuccess: Bool
    private let _isLoggedIn: Bool
    private let _contacts: [UserEntity]
    
    public let currentUser: UserEntity?
    public let isGuest: Bool
    
    public init(currentUser: UserEntity? = nil,
                isGuest: Bool = false,
                isLoggedIn: Bool = true,
                contacts: [UserEntity] = [],
                nodesCount: UInt = 0,
                getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity> = .failure(.nodeNotFound),
                accountDetails: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
                isUpgradeSecuritySuccess: Bool = false) {
        self.currentUser = currentUser
        self.isGuest = isGuest
        self._isLoggedIn = isLoggedIn
        self._contacts = contacts
        self.nodesCount = nodesCount
        self.getMyChatFilesFolderResult = getMyChatFilesFolderResult
        self.accountDetails = accountDetails
        self.isUpgradeSecuritySuccess = isUpgradeSecuritySuccess
    }
    
    public func isLoggedIn() -> Bool {
        _isLoggedIn
    }
    
    public func contacts() -> [UserEntity] {
        _contacts
    }
    
    public static var newRepo: MockAccountRepository {
        MockAccountRepository()
    }
    
    public func totalNodesCount() -> UInt { nodesCount }
    
    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }
    
    public func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void) {
        completion(accountDetails)
    }
    
    public func upgradeSecurity() async throws -> Bool {
        isUpgradeSecuritySuccess
    }
}
