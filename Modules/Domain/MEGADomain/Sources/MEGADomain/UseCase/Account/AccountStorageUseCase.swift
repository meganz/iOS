// MARK: - Use case protocol
public protocol AccountStorageUseCaseProtocol: Sendable {
    /// Determines whether not the given sequence of nodes will  exceed the active users storage quota limit.
    /// - Parameter nodes: Sequence of nodes to possibly be imported into account
    /// - Returns: True, if storage quote will exceed if the given nodes are added to the user account, else false.
    func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool
    
    ///  Refreshes the current account details, this needs to be called before using other operations to get most correct result.
    func refreshCurrentAccountDetails() async throws
}

public struct AccountStorageUseCase<T: AccountRepositoryProtocol>: AccountStorageUseCaseProtocol {
    
    private let accountRepository: T
    
    public init(accountRepository: T) {
        self.accountRepository = accountRepository
    }
    
    public func refreshCurrentAccountDetails() async throws {
        _ = try await accountRepository.refreshCurrentAccountDetails()
    }
    
    public func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool {
        guard let accountDetails = accountRepository.currentAccountDetails else {
            return true
        }
        
        let expectedNodesSize = nodes
            .reduce(0, { result, value in result + (Int64(exactly: value.size) ?? 0) })
        
        return accountDetails.storageUsed + expectedNodesSize > accountDetails.storageMax
    }
}
