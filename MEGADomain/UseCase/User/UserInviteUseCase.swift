

protocol UserInviteUseCaseProtocol {
    func sendInvite(forEmail email: String,
                    completion: @escaping (Result<Void, InviteError>) -> Void)
}

struct UserInviteUseCase: UserInviteUseCaseProtocol {
    private let repo: UserInviteRepositoryProtocol
    
    init(repo: UserInviteRepositoryProtocol) {
        self.repo = repo
    }
    
    func sendInvite(forEmail email: String, completion: @escaping (Result<Void, InviteError>) -> Void) {
        repo.sendInvite(forEmail: email, completion: completion)
    }
}
