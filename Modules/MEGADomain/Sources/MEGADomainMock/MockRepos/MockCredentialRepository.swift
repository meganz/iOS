import Foundation
import MEGADomain

public struct MockCredentialRepository: CredentialRepositoryProtocol {
    public static let newRepo = MockCredentialRepository()
    
    public func sessionId(service: String, account: String) -> String? { "" }
    public func clearSession() {}
    public func clearEphemeralSession() {}
}
