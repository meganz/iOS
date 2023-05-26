import MEGADomain

public struct MockAuthUseCase: AuthUseCaseProtocol {
    private let loginSessionId: String?
    private let isUserLoggedIn: Bool
    
    public init(loginSessionId: String? = nil, isUserLoggedIn: Bool = true) {
        self.loginSessionId = loginSessionId
        self.isUserLoggedIn = isUserLoggedIn
    }
    
    public func logout() { }
    
    public func login(sessionId: String) async throws { }
    
    public func sessionId() -> String? { loginSessionId }
    
    public func isLoggedIn() -> Bool { isUserLoggedIn }
}
