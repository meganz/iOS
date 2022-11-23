
public protocol UserInviteUseCaseProtocol {
    func sendInvite(forEmail email: String,
                    completion: @escaping (Result<Void, InviteErrorEntity>) -> Void)
}

public struct UserInviteUseCase<T: UserInviteRepositoryProtocol>: UserInviteUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func sendInvite(forEmail email: String, completion: @escaping (Result<Void, InviteErrorEntity>) -> Void) {
        repo.sendInvite(forEmail: email, completion: completion)
    }
}
