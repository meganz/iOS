import MEGADomain
import MEGASwift

public final class MockAccountStorageUseCase: AccountStorageUseCaseProtocol, @unchecked Sendable {
    private let willStorageQuotaExceed: Bool
    private let _shouldShowStorageBanner: Bool
    private let _isUnlimitedStorageAccount: Bool
    private let _isPaywalled: Bool
    public var _currentStorageStatus: StorageStatusEntity
    public var onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity>
    public var storageSumUpdates: AnyAsyncSequence<Int64>
    public var shouldRefreshStorageStatus: Bool
    
    public init(
        willStorageQuotaExceed: Bool = false,
        onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        storageSumUpdates: AnyAsyncSequence<Int64> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        currentStorageStatus: StorageStatusEntity = .noStorageProblems,
        shouldRefreshAccountDetails: Bool = false,
        shouldShowStorageBanner: Bool = false,
        isUnlimitedStorageAccount: Bool = false,
        isPaywalled: Bool = false
    ) {
        self.willStorageQuotaExceed = willStorageQuotaExceed
        self.onStorageStatusUpdates = onStorageStatusUpdates
        _currentStorageStatus = currentStorageStatus
        self.shouldRefreshStorageStatus = shouldRefreshAccountDetails
        self.storageSumUpdates = storageSumUpdates
        _shouldShowStorageBanner = shouldShowStorageBanner
        _isUnlimitedStorageAccount = isUnlimitedStorageAccount
        _isPaywalled = isPaywalled
    }
    
    public var currentStorageStatus: StorageStatusEntity {
        _currentStorageStatus
    }
    
    public func refreshCurrentStorageState() async throws -> StorageStatusEntity? {
        currentStorageStatus
    }
    
    public var shouldShowStorageBanner: Bool {
        _shouldShowStorageBanner
    }
    
    public func refreshCurrentAccountDetails() async throws {}
    
    public func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool {
        willStorageQuotaExceed
    }
    
    public func updateLastStorageBannerDismissDate() {}
    
    public var isUnlimitedStorageAccount: Bool {
        _isUnlimitedStorageAccount
    }
    
    public var isPaywalled: Bool {
        _isPaywalled
    }
}
