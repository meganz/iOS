import Foundation

// MARK: - Use case protocol -
protocol AuthUseCaseProtocol {
    func logout()
    func login(sessionId: String, delegate: MEGARequestDelegate)
    func sessionId() -> String?
    func isLoggedIn() -> Bool
}

// MARK: - Use case implementation -
struct AuthUseCase<T: AuthRepositoryProtocol, U: CredentialRepositoryProtocol>: AuthUseCaseProtocol {
    private let repo: T
    private let credentialRepo: U
    
    init(repo: T, credentialRepo: U) {
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
    
    func isLoggedIn() -> Bool {
        repo.isLoggedIn()
    }
}

fileprivate enum Constants {
    static let keychainServiceName = "MEGA"
    static let keychainAccountName = "sessionV3"
}
