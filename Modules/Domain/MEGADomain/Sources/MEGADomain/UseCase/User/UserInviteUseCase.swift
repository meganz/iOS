public protocol UserInviteUseCaseProtocol {
    func sendInvite(forEmail email: String) async throws
}

public struct UserInviteUseCase<T: UserInviteRepositoryProtocol>: UserInviteUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func sendInvite(forEmail email: String) async throws {
        try await repo.sendInvite(forEmail: email)
    }
}
