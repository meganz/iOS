public protocol CheckSMSUseCaseProtocol: Sendable {
    func checkVerificationCode(_ code: String) async throws -> String
    func sendVerification(toPhoneNumber: String) async throws -> String
    func checkState() -> SMSStateEntity
}

public struct CheckSMSUseCase<T: SMSRepositoryProtocol>: CheckSMSUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func checkVerificationCode(_ code: String) async throws -> String {
        try await repo.checkVerificationCode(code)
    }
    
    public func sendVerification(toPhoneNumber: String) async throws -> String {
        try await repo.sendVerification(toPhoneNumber: toPhoneNumber)
    }
    
    public func checkState() -> SMSStateEntity {
        repo.checkState()
    }
}
