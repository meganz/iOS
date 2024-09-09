import Foundation

public protocol AuthRepositoryProtocol: RepositoryProtocol, Sendable {
    func logout()
    func login(sessionId: String) async throws
}
