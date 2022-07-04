import Foundation
@testable import MEGA

struct MockCredentialRepository: CredentialRepositoryProtocol {
    static let newRepo = MockCredentialRepository()
    
    func sessionId(service: String, account: String) -> String? { "" }
    func clearSession() {}
    func clearEphemeralSession() {}
}
