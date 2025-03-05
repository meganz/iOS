import Foundation
import MEGASwift

// MARK: - Use case protocol
public protocol AccountStorageUseCaseProtocol: Sendable {
    /// Determines whether not the given sequence of nodes will  exceed the active users storage quota limit.
    /// - Parameter nodes: Sequence of nodes to possibly be imported into account
    /// - Returns: True, if storage quote will exceed if the given nodes are added to the user account, else false.
    func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool
    
    /// Refreshes the current account details, this needs to be called before using other operations to get most correct result.
    func refreshCurrentAccountDetails() async throws
    
    /// Refreshes the current storage state of the account.
    ///
    /// This method retrieves the latest storage state of the user's account, such as whether the account is nearing full storage capacity or has exceeded its limit.
    ///
    /// - Returns: An optional `StorageStatusEntity` indicating the current storage status of the account.
    func refreshCurrentStorageState() async throws -> StorageStatusEntity?
    
    /// Updates the last dismissed date for the storage banner.
    ///
    /// This method stores the current date as the last time the storage banner was dismissed. The banner will not be shown again until the configured duration has passed.
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
    /// If the account has unlimited storage (e.g., Business or Pro Flexi plans), this will always return
    /// `.noStorageProblems` regardless of the actual storage usage.
    ///
    /// - Returns: A `StorageStatusEntity` indicating the current state of the user's account storage.
    /// It can return:
    ///   - `.noStorageProblems` for users who are not close to exceeding or exceeding their storage limit or
    ///      for unlimited storage accounts (Business, Pro Flexi).
    ///   - `.almostFull` when the account is nearing the storage limit.
    ///   - `.full` when the account has exceeded the storage limit.
    var currentStorageStatus: StorageStatusEntity { get }
    
    /// A boolean value indicating whether the storage status should be refreshed.
    ///
    /// If `true`, the storage status should be refreshed to ensure accurate data is presented.
    var shouldRefreshStorageStatus: Bool { get }
    
    /// A boolean value indicating whether the storage banner should be shown.
    ///
    /// The storage banners are displayed when the user is nearing or exceeding their storage quota.
    /// This method determines whether a storage banner should be shown based on the current storage status,
    /// the time since the last dismissal of the banner, and whether the account has unlimited storage.
    ///
    /// - The banner is not shown if the account has unlimited storage (e.g., Business or Pro Flexi).
    /// - The banner is shown in two cases:
    ///   1. The account has exceeded its storage limit (storage status is `.full`).
    ///   2. The account is almost full (storage status is `.almostFull`), and enough time has passed since
    ///      the banner was last dismissed (more than 24 hours).
    ///
    /// - Returns: `true` if the storage banner should be shown based on the user's storage status
    /// and banner dismissal rules. Returns `false` if the banner should not be shown, either because
    /// the account has unlimited storage or the banner has been dismissed recently.
    var shouldShowStorageBanner: Bool { get }
    
    /// A boolean value indicating whether the user account has unlimited storage.
    ///
    /// This property is used to prevent the display of storage-related banners or warnings
    /// for users with unlimited storage accounts, such as Business or Pro Flexi plans.
    var isUnlimitedStorageAccount: Bool { get }
    
    ///  A Boolean value indicating whether the account is paywalled.
    ///
    /// - Returns: `true` if the account is paywalled.
    var isPaywalled: Bool { get }
}

public struct AccountStorageUseCase: AccountStorageUseCaseProtocol {
    private let accountRepository: any AccountRepositoryProtocol
    private var storageBannerDismissDuration: TimeInterval {
        24 * 60 * 60 // 24 hours in seconds.
    }
    private let currentDate: @Sendable () -> Date
    
    @PreferenceWrapper(key: .lastStorageBannerDismissedDate, defaultValue: nil)
    private var lastStorageBannerDismissedDate: Date?
    
    public init(
        accountRepository: some AccountRepositoryProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol,
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.accountRepository = accountRepository
        self.currentDate = currentDate
        
        $lastStorageBannerDismissedDate.useCase = preferenceUseCase
    }
    
    public func refreshCurrentAccountDetails() async throws {
        _ = try await accountRepository.refreshCurrentAccountDetails()
    }
    
    public func refreshCurrentStorageState() async throws -> StorageStatusEntity? {
        try await accountRepository.refreshCurrentStorageState()
    }
    
    public func updateLastStorageBannerDismissDate() {
        lastStorageBannerDismissedDate = currentDate()
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
        guard !isUnlimitedStorageAccount else { return .noStorageProblems }
        return accountRepository.currentStorageStatus
    }
    
    public var shouldRefreshStorageStatus: Bool {
        accountRepository.shouldRefreshStorageStatus
    }
    
    public var shouldShowStorageBanner: Bool {
        isFullStorageStatus || (isAlmostFullStorageStatus && shouldShowAlmostFullBanner)
    }
    
    public var isUnlimitedStorageAccount: Bool {
        accountRepository.isUnlimitedStorageAccount
    }

    private var isFullStorageStatus: Bool {
        accountRepository.currentStorageStatus == .full
    }

    private var isAlmostFullStorageStatus: Bool {
        accountRepository.currentStorageStatus == .almostFull
    }

    private var shouldShowAlmostFullBanner: Bool {
        guard let lastDismissedDate = lastStorageBannerDismissedDate else {
            return true
        }
        return currentDate().timeIntervalSince(lastDismissedDate) > storageBannerDismissDuration
    }
    
    public var isPaywalled: Bool {
        accountRepository.isPaywalled
    }
}
