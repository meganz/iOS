import Foundation

protocol CredentialRepositoryProtocol: RepositoryProtocol {
    func sessionId(service: String, account: String) -> String?
    func clearSession()
    func clearEphemeralSession()
}
