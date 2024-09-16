import MEGADomain
import MEGASwift

public struct MockAccountStorageUseCase: AccountStorageUseCaseProtocol {
    private let willStorageQuotaExceed: Bool
    
    public init(
        willStorageQuotaExceed: Bool = false,
        onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        currentStorageStatus: StorageStatusEntity = .noStorageProblems
    ) {
        self.willStorageQuotaExceed = willStorageQuotaExceed
        self.onStorageStatusUpdates = onStorageStatusUpdates
        self.currentStorageStatus = currentStorageStatus
    }
    
    public func refreshCurrentAccountDetails() async throws { }
    
    public func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool {
        willStorageQuotaExceed
    }
    
    public var onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity>
    
    public var currentStorageStatus: StorageStatusEntity
}
