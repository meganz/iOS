import Foundation

protocol CredentialRepositoryProtocol {
    func sessionId(service: String, account: String) -> String?
}
