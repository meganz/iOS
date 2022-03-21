

protocol UserInviteUseCaseProtocol {
    func sendInvite(forEmail email: String,
                    completion: @escaping (Result<Void, InviteErrorEntity>) -> Void)
}

struct UserInviteUseCase<T: UserInviteRepositoryProtocol>: UserInviteUseCaseProtocol {
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func sendInvite(forEmail email: String, completion: @escaping (Result<Void, InviteErrorEntity>) -> Void) {
        repo.sendInvite(forEmail: email, completion: completion)
    }
}
