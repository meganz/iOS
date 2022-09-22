import MEGADomain

public struct MockAccountRepository: AccountRepositoryProtocol {
    let nodesCount: UInt
    let getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>)
    let accountDetails: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>)
    let existsBackupNode: Bool
    
    public init(nodesCount: UInt,
                getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity> = .failure(.nodeNotFound),
                accountDetails: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
                existsBackupNode: Bool = false) {
        self.nodesCount = nodesCount
        self.getMyChatFilesFolderResult = getMyChatFilesFolderResult
        self.accountDetails = accountDetails
        self.existsBackupNode = existsBackupNode
    }
    
    public func totalNodesCount() -> UInt { nodesCount }
    
    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }
    
    public func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void) {
        completion(accountDetails)
    }
    
    public func inboxNode() -> NodeEntity? {
        NodeEntity(name: "inbox", handle: 1)
    }
    
    public func existsBackupNode() async throws -> Bool {
        existsBackupNode
    }
}
