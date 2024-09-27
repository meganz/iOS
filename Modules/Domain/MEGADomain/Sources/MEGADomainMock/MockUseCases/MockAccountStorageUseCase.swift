import MEGADomain
import MEGASwift

public final class MockAccountStorageUseCase: AccountStorageUseCaseProtocol, @unchecked Sendable {
    private let willStorageQuotaExceed: Bool
    private let _shouldShowStorageBanner: Bool
    
    public var _currentStorageStatus: StorageStatusEntity
    
    public init(
        willStorageQuotaExceed: Bool = false,
        onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        currentStorageStatus: StorageStatusEntity = .noStorageProblems,
        shouldRefreshAccountDetails: Bool = false,
        shouldShowStorageBanner: Bool = false
    ) {
        self.willStorageQuotaExceed = willStorageQuotaExceed
        self.onStorageStatusUpdates = onStorageStatusUpdates
        _currentStorageStatus = currentStorageStatus
        self.shouldRefreshAccountDetails = shouldRefreshAccountDetails
        _shouldShowStorageBanner = shouldShowStorageBanner
    }
    
    public var onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity>
    
    public var currentStorageStatus: StorageStatusEntity {
        _currentStorageStatus
    }
    
    public var shouldRefreshAccountDetails: Bool
    
    public var shouldShowStorageBanner: Bool {
        _shouldShowStorageBanner
    }
    
    public func refreshCurrentAccountDetails() async throws { }
    
    public func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool {
        willStorageQuotaExceed
    }
    
    public func updateLastStorageBannerDismissDate() {}
}
