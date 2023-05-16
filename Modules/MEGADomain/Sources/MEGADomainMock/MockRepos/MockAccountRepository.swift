import MEGADomain

public struct MockAccountRepository: AccountRepositoryProtocol {
    private let nodesCount: UInt
    private let getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>)
    private let accountDetails: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>)
    private let isUpgradeSecuritySuccess: Bool
    private let _isLoggedIn: Bool
    private let _contacts: [UserEntity]
    private let contactsRequestsCount: Int
    private let unseenUserAlertsCount: UInt
    
    let currentUser: UserEntity?
    public let isGuest: Bool
    
    public init(currentUser: UserEntity? = nil,
                isGuest: Bool = false,
                isLoggedIn: Bool = true,
                contacts: [UserEntity] = [],
                nodesCount: UInt = 0,
                contactsRequestsCount: Int = 0,
                unseenUserAlertsCount: UInt = 0,
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
        self.contactsRequestsCount = contactsRequestsCount
        self.unseenUserAlertsCount = unseenUserAlertsCount
    }
    
    public var currentUserHandle: HandleEntity? {
        currentUser?.handle
    }
    
    public func currentUser() async -> UserEntity? {
        currentUser
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
    
    public func accountDetails() async throws -> AccountDetailsEntity {
        switch accountDetails {
        case .success(let details): return details
        case .failure(let error): throw error
        }
    }
    
    public func upgradeSecurity() async throws -> Bool {
        isUpgradeSecuritySuccess
    }
    
    public func incomingContactsRequestsCount() -> Int {
        contactsRequestsCount
    }
    
    public func relevantUnseenUserAlertsCount() -> UInt {
        unseenUserAlertsCount
    }
}
