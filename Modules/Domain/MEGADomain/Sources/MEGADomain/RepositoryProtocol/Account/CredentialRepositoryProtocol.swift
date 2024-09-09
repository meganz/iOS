import Foundation

public protocol CredentialRepositoryProtocol: RepositoryProtocol, Sendable {
    func sessionId() -> String?
    func clearSession()
    func clearEphemeralSession()
    func isPasscodeEnabled() -> Bool
}
