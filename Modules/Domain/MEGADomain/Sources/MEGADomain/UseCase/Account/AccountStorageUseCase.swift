// MARK: - Use case protocol
public protocol AccountStorageUseCaseProtocol {
    /// Determines whether not the given sequence of nodes will  exceed the active users storage quota limit.
    /// - Parameter nodes: Sequence of nodes to possibly be imported into account
    /// - Returns: True, if storage quote will exceed if the given nodes are added to the user account, else false.
    func willStorageQuotaExceed(after nodes: any Sequence<NodeEntity>) -> Bool
}

public struct AccountStorageUseCase<T: AccountRepositoryProtocol>: AccountStorageUseCaseProtocol {
    
    private let accountRepository: T
    
    public init(accountRepository: T) {
        self.accountRepository = accountRepository
    }
    
    public func willStorageQuotaExceed(after nodes: any Sequence<NodeEntity>) -> Bool {
        guard let accountDetails = accountRepository.currentAccountDetails else {
            return true
        }
        
        let expectedNodesSize: UInt64 = nodes
            .reduce(0, { result, value in result + value.size })
        
        return accountDetails.storageUsed + expectedNodesSize > accountDetails.storageMax
    }
}
