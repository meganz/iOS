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
        isLoggedIn = sdk.isLoggedIn() != 0
        
        registerAccountNotifications()
    }
    
    public private(set) var currentUserHandle: HandleEntity?
    public private(set) var currentUserEmail: String?
    public private(set) var isLoggedIn: Bool
    
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
            .publisher(for: .accountLoginNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                let user = sdk.myUser
                currentUserHandle = user?.handle
                currentUserEmail = user?.email
                isLoggedIn = true
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .accountLogoutNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                currentUserHandle = nil
                currentUserEmail = nil
                isLoggedIn = false
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .accountEmailChangedNotification)
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
