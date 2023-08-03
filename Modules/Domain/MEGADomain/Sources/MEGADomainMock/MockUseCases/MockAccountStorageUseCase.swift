import MEGADomain

public struct MockAccountStorageUseCase: AccountStorageUseCaseProtocol {
    
    private let willStorageQuotaExceed: Bool
    
    public init(willStorageQuotaExceed: Bool = false) {
        self.willStorageQuotaExceed = willStorageQuotaExceed
    }
    
    public func refreshCurrentAccountDetails() async throws { }
    
    public func willStorageQuotaExceed(after nodes: some Sequence<MEGADomain.NodeEntity>) -> Bool {
        willStorageQuotaExceed
    }
}
