import MEGADomain

public struct MockAccountUseCase: AccountUseCaseProtocol {
    let totalNodesCountVariable: UInt
    let getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>)
    let accountDetails: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>)
    
    public init(totalNodesCountVariable: UInt = 0,
                getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity> = .failure(.nodeNotFound),
                accountDetails: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic)) {
        self.totalNodesCountVariable = totalNodesCountVariable
        self.getMyChatFilesFolderResult = getMyChatFilesFolderResult
        self.accountDetails = accountDetails
    }
    
    public func totalNodesCount() -> UInt {
        totalNodesCountVariable
    }
    
    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }
    
    public func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void) {
        completion(accountDetails)
    }
}
