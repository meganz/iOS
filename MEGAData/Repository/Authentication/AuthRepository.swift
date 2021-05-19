import Foundation

struct AuthRepository: AuthRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func logout() {
        sdk.logout()
    }
    
    func login(sessionId: String, delegate: MEGARequestDelegate) {
        sdk.fastLogin(withSession: sessionId, delegate: delegate)
    }
    
    func isLoggedIn() -> Bool {
        sdk.isLoggedIn() > 0
    }
}
