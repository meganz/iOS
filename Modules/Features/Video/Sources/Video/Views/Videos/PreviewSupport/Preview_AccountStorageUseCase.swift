import MEGADomain
import MEGASwift

struct Preview_AccountStorageUseCase: AccountStorageUseCaseProtocol {
    let onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    let currentStorageStatus: StorageStatusEntity = .noStorageProblems
    let shouldRefreshStorageStatus: Bool = false
    let shouldShowStorageBanner: Bool  = false
    let isUnlimitedStorageAccount: Bool = false
    let isPaywalled: Bool = false
    
    func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool {
        false
    }
    
    func refreshCurrentAccountDetails() async throws { }
    
    func refreshCurrentStorageState() async throws -> StorageStatusEntity? {
        nil
    }
    
    func updateLastStorageBannerDismissDate() { }
}
