
protocol UserUseCaseProtocol {
    var myHandle: UInt64? { get }
    func user(withHandle handle: UInt64) -> UserSDKEntity?
}

struct UserUseCase: UserUseCaseProtocol {
    private let repo: SDKUserClient
    
    var myHandle: UInt64? {
        return repo.currentUser()?.handle
    }
    
    init(repo: SDKUserClient) {
        self.repo = repo
    }
    
    func user(withHandle handle: UInt64) -> UserSDKEntity? {
        return repo.userForSharedNode(handle)
    }
}
