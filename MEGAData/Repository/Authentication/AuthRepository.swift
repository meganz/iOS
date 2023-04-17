import Foundation
import MEGADomain
import MEGAData

struct AuthRepository: AuthRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func logout() {
        sdk.logout()
    }
    
    func login(sessionId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            sdk.fastLogin(withSession: sessionId, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
    
    func isLoggedIn() -> Bool {
        sdk.isLoggedIn() > 0
    }
}
