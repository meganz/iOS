import Foundation
import MEGADomain
import MEGASdk

public struct AuthRepository: AuthRepositoryProtocol {
    public static var newRepo: AuthRepository {
        AuthRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func logout() {
        sdk.logout()
    }
    
    public func login(sessionId: String) async throws {
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
}
