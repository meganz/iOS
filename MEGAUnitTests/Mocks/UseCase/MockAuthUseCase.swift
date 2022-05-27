@testable import MEGA

struct MockAuthUseCase: AuthUseCaseProtocol {
    var loginSessionId: String? = nil
    var isUserLoggedIn: Bool
    
    func logout() { }
    
    func login(sessionId: String, delegate: MEGARequestDelegate) { }
    
    func sessionId() -> String? { loginSessionId }
    
    func isLoggedIn() -> Bool { isUserLoggedIn }
}
