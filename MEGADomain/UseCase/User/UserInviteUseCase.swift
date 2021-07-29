

protocol UserInviteUseCaseProtocol {
    func sendInvite(forEmail email: String,
                    completion: @escaping (Result<Void, InviteErrorEntity>) -> Void)
}

struct UserInviteUseCase: UserInviteUseCaseProtocol {
    private let repo: UserInviteRepositoryProtocol
    
    init(repo: UserInviteRepositoryProtocol) {
        self.repo = repo
    }
    
    func sendInvite(forEmail email: String, completion: @escaping (Result<Void, InviteErrorEntity>) -> Void) {
        repo.sendInvite(forEmail: email, completion: completion)
    }
}
