@testable import MEGA

struct MockAuthUseCase: AuthUseCaseProtocol {
    var loginSessionId: String? = nil
    
    func logout() { }
    
    func login(sessionId: String, delegate: MEGARequestDelegate) { }
    
    func sessionId() -> String? { loginSessionId }
}
