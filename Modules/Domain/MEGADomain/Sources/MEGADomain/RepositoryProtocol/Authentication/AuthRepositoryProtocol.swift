import Foundation

public protocol AuthRepositoryProtocol: RepositoryProtocol {
    func logout()
    func login(sessionId: String) async throws
}
