
struct MockAccountUseCase: AccountUseCaseProtocol {
    var totalNodesCountVariable: UInt = 0
    var getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>) = .failure(.nodeNotFound)
    var accountDetails: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) = .failure(.generic)
    
    func totalNodesCount() -> UInt {
        totalNodesCountVariable
    }
    
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }
    
    func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void) {
        completion(accountDetails)
    }
}
