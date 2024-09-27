import Foundation
import MEGASwift

// MARK: - Use case protocol
public protocol AccountStorageUseCaseProtocol: Sendable {
    /// Determines whether not the given sequence of nodes will  exceed the active users storage quota limit.
    /// - Parameter nodes: Sequence of nodes to possibly be imported into account
    /// - Returns: True, if storage quote will exceed if the given nodes are added to the user account, else false.
    func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool
    
    ///  Refreshes the current account details, this needs to be called before using other operations to get most correct result.
    func refreshCurrentAccountDetails() async throws
    
    func updateLastStorageBannerDismissDate()
    
    /// An asynchronous sequence that emits `StorageStatusEntity` updates from multiple sources.
    /// This property emits storage status updates from both the regular storage status updates stream
    /// and the account details request finish storage updates stream.
    ///
    /// Use this property to receive updates on the storage status of the account.
    /// It will emit values as soon as either of the following occurs:
    /// - A new storage status update is available from the account's storage status.
    /// - The account details request finishes and provides storage status updates.
    var onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> { get }
    
    /// Retrieves the current storage status of the user's account.
    ///
    /// The storage status reflects the current usage of storage compared to the maximum available quota.
    /// The value can indicate whether the user is under quota, nearing quota, or has exceeded their storage limit.
    ///
    /// - Returns: A `StorageStatusEntity` indicating the current state of the user's account storage.
    /// It can return `.noStorageProblems`, `.almostFull`, or `.full` based on the storage usage.
    var currentStorageStatus: StorageStatusEntity { get }
    
    var shouldRefreshAccountDetails: Bool { get }
    var shouldShowStorageBanner: Bool { get }
}

public struct AccountStorageUseCase: AccountStorageUseCaseProtocol {
    private let accountRepository: any AccountRepositoryProtocol
    private let storageBannerDismissDuration: TimeInterval = 24 * 60 * 60 // 24 hours in seconds
    
    @PreferenceWrapper(key: .lastStorageBannerDismissedDate, defaultValue: nil)
    private var lastStorageBannerDismissedDate: Date?
    
    public init(
        accountRepository: some AccountRepositoryProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol
    ) {
        self.accountRepository = accountRepository
        
        $lastStorageBannerDismissedDate.useCase = preferenceUseCase
    }
    
    public func refreshCurrentAccountDetails() async throws {
        _ = try await accountRepository.refreshCurrentAccountDetails()
    }
    
    public func updateLastStorageBannerDismissDate() {
        lastStorageBannerDismissedDate = Date()
    }
    
    public func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool {
        guard let accountDetails = accountRepository.currentAccountDetails else {
            return true
        }
        
        let expectedNodesSize = nodes
            .reduce(0, { result, value in result + (Int64(exactly: value.size) ?? 0) })
        
        return accountDetails.storageUsed + expectedNodesSize > accountDetails.storageMax
    }
    
    public var onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> {
        accountRepository.onStorageStatusUpdates
    }
    
    public var currentStorageStatus: StorageStatusEntity {
        accountRepository.currentStorageStatus
    }
    
    public var shouldRefreshAccountDetails: Bool {
        accountRepository.shouldRefreshAccountDetails
    }
    
    public var shouldShowStorageBanner: Bool {
        guard let lastStorageBannerDismissedDate else {
            return true
        }
        return Date().timeIntervalSince(lastStorageBannerDismissedDate) > storageBannerDismissDuration
    }
}
