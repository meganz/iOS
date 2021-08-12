
protocol UserUseCaseProtocol {
    var myHandle: UInt64? { get }
    var isLoggedIn: Bool { get }
    var isGuest: Bool { get }
    func user(withHandle handle: UInt64) -> UserSDKEntity?
}

struct UserUseCase: UserUseCaseProtocol {
    private let repo: SDKUserClient
    
    var myHandle: UInt64? {
        repo.currentUser()?.handle
    }
    
    var isLoggedIn: Bool {
        repo.isLoggedIn()
    }
    
    var isGuest: Bool {
        repo.isGuest()
    }
    
    init(repo: SDKUserClient) {
        self.repo = repo
    }
    
    func user(withHandle handle: UInt64) -> UserSDKEntity? {
        repo.userForSharedNode(handle)
    }
}
