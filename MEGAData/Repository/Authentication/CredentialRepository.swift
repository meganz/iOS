import Foundation

struct CredentialRepository: CredentialRepositoryProtocol {
    func sessionId(service: String, account: String) -> String? {
        SAMKeychain.password(forService: service, account: account)
    }
}
