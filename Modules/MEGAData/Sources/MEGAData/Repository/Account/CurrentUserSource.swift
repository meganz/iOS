import MEGADomain
import Combine
import MEGASdk

public final class CurrentUserSource {
    public static let shared = CurrentUserSource(sdk: MEGASdk.sharedSdk)
    
    private let sdk: MEGASdk
    private var subscriptions = Set<AnyCancellable>()
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
        let user = sdk.myUser
        currentUserHandle = user?.handle
        currentUserEmail = user?.email
        
        registerAccountNotifications()
    }
    
    public var currentUserHandle: HandleEntity?
    public var currentUserEmail: String?
    
    public var isGuest: Bool {
        currentUserEmail?.isEmpty != false
    }
    
    public func currentUser() async -> UserEntity? {
        await Task.detached {
            self.sdk.myUser?.toUserEntity()
        }.value
    }
    
    private func registerAccountNotifications() {
        NotificationCenter
            .default
            .publisher(for: .accountDidLogin)
            .sink { [weak self] _ in
                self?.currentUserHandle = self?.sdk.myUser?.handle
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .accountDidLogout)
            .sink { [weak self] _ in
                self?.currentUserHandle = nil
                self?.currentUserEmail = nil
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .accountDidFinishFetchNodes)
            .sink { [weak self] _ in
                self?.currentUserEmail = self?.sdk.myUser?.email
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .accountEmailDidChange)
            .compactMap {
                $0.userInfo?["user"] as? MEGAUser
            }
            .filter { [weak self] in
                $0.handle == self?.currentUserHandle
            }
            .sink { [weak self] in
                self?.currentUserEmail = $0.email
            }
            .store(in: &subscriptions)
    }
}
