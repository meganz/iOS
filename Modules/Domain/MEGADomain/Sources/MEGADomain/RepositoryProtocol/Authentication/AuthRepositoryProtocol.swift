import Foundation

public protocol AuthRepositoryProtocol {
    func logout()
    func login(sessionId: String) async throws
}
