import Foundation

public protocol CredentialRepositoryProtocol: RepositoryProtocol {
    func sessionId() -> String?
    func clearSession()
    func clearEphemeralSession()
    func isPasscodeEnabled() -> Bool
}
