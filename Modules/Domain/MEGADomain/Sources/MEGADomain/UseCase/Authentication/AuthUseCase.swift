import Foundation

public protocol AuthUseCaseProtocol: Sendable {
    func logout()
    func login(sessionId: String) async throws
    func sessionId() -> String?
}

public struct AuthUseCase<T: AuthRepositoryProtocol, U: CredentialRepositoryProtocol>: AuthUseCaseProtocol {
    private let repo: T
    private let credentialRepo: U
    
    public init(repo: T, credentialRepo: U) {
        self.repo = repo
        self.credentialRepo = credentialRepo
    }
    
    public func logout() {
        repo.logout()
    }
    
    public func login(sessionId: String) async throws {
        try await repo.login(sessionId: sessionId)
    }
    
    public func sessionId() -> String? {
        credentialRepo.sessionId()
    }
}
