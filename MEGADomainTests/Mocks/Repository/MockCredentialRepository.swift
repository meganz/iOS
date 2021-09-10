import Foundation
@testable import MEGA

struct MockCredentialRepository: CredentialRepositoryProtocol {
    func sessionId(service: String, account: String) -> String? { "" }
    func clearSession() {}
    func clearEphemeralSession() {}
}
