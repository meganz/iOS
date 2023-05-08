import MEGADomain
import Combine
import MEGASdk

public final class CurrentUserSource {
    public static let shared = CurrentUserSource(sdk: MEGASdk.sharedSdk)
    
    private let sdk: MEGASdk
    private var subscriptions = Set<AnyCancellable>()
    init(sdk: MEGASdk) {
        self.sdk = sdk
        currentUserHandle = sdk.myUser?.handle
        registerAccountNotifications()
    }
    
    public var currentUserHandle: HandleEntity?
    
    public func currentUser() async -> UserEntity? {
        await Task.detached {
            self.sdk.myUser?.toUserEntity()
        }.value
    }
    
    private func registerAccountNotifications() {
        NotificationCenter
            .default
            .publisher(for: .accountLoginNotification)
            .sink { [weak self] _ in
                self?.currentUserHandle = self?.sdk.myUser?.handle
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .accountLogoutNotification)
            .sink { [weak self] _ in
                self?.currentUserHandle = nil
            }
            .store(in: &subscriptions)
    }
}
