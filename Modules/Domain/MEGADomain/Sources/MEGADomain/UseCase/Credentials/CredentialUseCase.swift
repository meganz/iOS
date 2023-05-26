
public protocol CredentialUseCaseProtocol {
    func hasSession() -> Bool
    func isPasscodeEnabled() -> Bool
}

public struct CredentialUseCase<T: CredentialRepositoryProtocol>: CredentialUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func hasSession() -> Bool {
        repo.sessionId() != nil
    }
    
    public func isPasscodeEnabled() -> Bool {
        repo.isPasscodeEnabled()
    }
}
