import Foundation

// MARK: - Use case protocol -
protocol AuthUseCaseProtocol {
    func logout()
    func login(sessionId: String, delegate: MEGARequestDelegate)
    func sessionId() -> String?
}

// MARK: - Use case implementation -
struct AuthUseCase: AuthUseCaseProtocol {
    private enum Constants {
        static let keychainServiceName = "MEGA"
        static let keychainAccountName = "sessionV3"
    }
    
    private let repo: AuthRepositoryProtocol
    private let credentialRepo: CredentialRepositoryProtocol
    
    init(repo: AuthRepositoryProtocol, credentialRepo: CredentialRepositoryProtocol = CredentialRepository()) {
        self.repo = repo
        self.credentialRepo = credentialRepo
    }
    
    func logout() {
        repo.logout()
    }
    
    func login(sessionId: String, delegate: MEGARequestDelegate) {
        repo.login(sessionId: sessionId, delegate: delegate)
    }
    
    func sessionId() -> String? {
        credentialRepo.sessionId(service: Constants.keychainServiceName, account: Constants.keychainAccountName)
    }
}
