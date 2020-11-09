import Foundation

protocol AuthRepositoryProtocol {
    func logout()
    func login(sessionId: String, delegate: MEGARequestDelegate)
}
