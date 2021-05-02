
protocol UserUseCaseProtocol {
    var myHandle: UInt64? { get }
    var hasUserLoggedIn: Bool { get }
    func user(withHandle handle: UInt64) -> UserSDKEntity?
}

struct UserUseCase: UserUseCaseProtocol {
    private let repo: SDKUserClient
    
    var myHandle: UInt64? {
        repo.currentUser()?.handle
    }
    
    var hasUserLoggedIn: Bool {
        repo.hasUserLoggedIn()
    }
    
    init(repo: SDKUserClient) {
        self.repo = repo
    }
    
    func user(withHandle handle: UInt64) -> UserSDKEntity? {
        repo.userForSharedNode(handle)
    }
}
