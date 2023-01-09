import Foundation
import MEGADomain

public struct MockCredentialRepository: CredentialRepositoryProtocol {
    public static let newRepo = MockCredentialRepository()
    
    public func sessionId() -> String? { "" }
    public func clearSession() {}
    public func clearEphemeralSession() {}
    public func isPasscodeEnabled() -> Bool { false }
}
