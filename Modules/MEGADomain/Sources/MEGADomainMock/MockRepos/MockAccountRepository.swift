import MEGADomain

public struct MockAccountRepository: AccountRepositoryProtocol {
    let nodesCount: UInt
    let getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>)
    let accountDetails: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>)
    
    public init(nodesCount: UInt,
                getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity> = .failure(.nodeNotFound),
                accountDetails: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic)) {
        self.nodesCount = nodesCount
        self.getMyChatFilesFolderResult = getMyChatFilesFolderResult
        self.accountDetails = accountDetails
    }
    
    public func totalNodesCount() -> UInt { nodesCount }
    
    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }
    
    public func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void) {
        completion(accountDetails)
    }
}
