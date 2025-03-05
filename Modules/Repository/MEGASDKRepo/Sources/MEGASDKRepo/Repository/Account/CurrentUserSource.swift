import Combine
import MEGADomain
import MEGASdk
import MEGASwift

public final class CurrentUserSource: @unchecked Sendable {
    public static let shared = CurrentUserSource(sdk: MEGASdk.sharedSdk)
    
    private let sdk: MEGASdk
    private let notificationCenter: NotificationCenter
    private var subscriptions = Set<AnyCancellable>()
    private var _currentUserHandle: Atomic<HandleEntity?>
    private var _currentUserEmail: Atomic<String?>
    private var _isLoggedIn: Atomic<Bool>
    @Atomic private var _shouldRefreshAccountDetails: Bool = false
    @Atomic private var _accountDetails: AccountDetailsEntity?
    @Atomic private var _storageStatus: StorageStatusEntity?
    /// Important: This is separate from storage status due to `sdk.getUserAttributeType(.storageState` returning `full` on the paywalled account.
    /// The value is updated via `onEvent` type `storage`
    @Atomic private var _isPaywalled = false
    
    public init(
        sdk: MEGASdk,
        notificationCenter: NotificationCenter = .default
    ) {
        self.sdk = sdk
        self.notificationCenter = notificationCenter
        let user = sdk.myUser
        _currentUserHandle = Atomic(wrappedValue: user?.handle)
        _currentUserEmail = Atomic(wrappedValue: user?.email)
        _isLoggedIn = Atomic(wrappedValue: sdk.isLoggedIn() > 0)
        
        registerAccountNotifications()
    }
    
    public var currentUserHandle: HandleEntity? {
        _currentUserHandle.wrappedValue
    }
    public var currentUserEmail: String? {
        _currentUserEmail.wrappedValue
    }
    public var isLoggedIn: Bool {
        _isLoggedIn.wrappedValue
    }
    
    public var accountDetails: AccountDetailsEntity? {
        _accountDetails
    }
    public var storageStatus: StorageStatusEntity? {
        _storageStatus
    }
    
    public var isGuest: Bool {
        currentUserEmail?.isEmpty != false
    }
    
    /// - Returns: A Boolean value indicating whether the account is paywalled.
    public var isPaywalled: Bool {
        _isPaywalled
    }
    
    public func currentUser() async -> UserEntity? {
        await Task.detached {
            self.sdk.myUser?.toUserEntity()
        }.value
    }
    
    private func registerAccountNotifications() {
        notificationCenter
            .publisher(for: .accountDidLogin)
            .sink { [weak self] _ in
                guard let self else { return }
                _currentUserHandle.mutate { $0 = self.sdk.myUser?.handle }
                _isLoggedIn.mutate { $0 = true }
            }
            .store(in: &subscriptions)
        
        notificationCenter
            .publisher(for: .accountDidLogout)
            .sink { [weak self] _ in
                guard let self else { return }
                _currentUserHandle.mutate { $0 = nil }
                _currentUserEmail.mutate { $0 = nil }
                _isLoggedIn.mutate { $0 = false }
                $_shouldRefreshAccountDetails.mutate { $0 = false }
                $_accountDetails.mutate { $0 = nil }
                $_storageStatus.mutate { $0 = nil }
                $_isPaywalled.mutate { $0 = false }
            }
            .store(in: &subscriptions)
        
        notificationCenter
            .publisher(for: .accountDidFinishFetchNodes)
            .sink { [weak self] _ in
                self?._currentUserEmail.mutate { $0 = self?.sdk.myUser?.email }
            }
            .store(in: &subscriptions)
        
        notificationCenter
            .publisher(for: .accountEmailDidChange)
            .compactMap {
                $0.userInfo?["user"] as? MEGAUser
            }
            .filter { [weak self] in
                $0.handle == self?.currentUserHandle
            }
            .sink { [weak self] user in
                self?._currentUserEmail.mutate { $0 = user.email }
            }
            .store(in: &subscriptions)
        
        notificationCenter
            .publisher(for: .accountDidFinishFetchAccountDetails)
            .compactMap { $0.object as? AccountDetailsEntity }
            .sink { [weak self] accountDetails in
                self?.setAccountDetails(accountDetails)
            }
            .store(in: &subscriptions)
        
        notificationCenter
            .publisher(for: .storageStatusDidChange)
            .compactMap { $0.object as? StorageStatusEntity }
            .sink { [weak self] storageStatus in
                self?.setStorageStatus(storageStatus)
            }
            .store(in: &subscriptions)
        
        notificationCenter
            .publisher(for: .storageEventDidChange)
            .compactMap {
                guard let eventNumber = ($0.userInfo?[NotificationUserInfoKey.storageEventState] as? UInt),
                      let storeState = StorageState(rawValue: eventNumber) else {
                    return nil
                }
                return storeState == .paywall
            }
            .sink { [weak self] isPaywalled in
                self?.$_isPaywalled.mutate { $0 = isPaywalled }
            }
            .store(in: &subscriptions)
    }
    
    public func setAccountDetails(_ userAccountDetails: AccountDetailsEntity?) {
        $_accountDetails.mutate { $0 = userAccountDetails }
    }
    
    public func setStorageStatus(_ storageStatus: StorageStatusEntity) {
        $_storageStatus.mutate { $0 = storageStatus }
    }
}
