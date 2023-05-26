
public protocol CheckSMSUseCaseProtocol {
    func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void)
    func sendVerification(toPhoneNumber: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void)
    func checkState() -> SMSStateEntity
}

public struct CheckSMSUseCase<T: SMSRepositoryProtocol>: CheckSMSUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        repo.checkVerificationCode(code, completion: completion)
    }

    public func sendVerification(toPhoneNumber: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        
        repo.sendVerification(toPhoneNumber: toPhoneNumber, completion: completion)
    }
    
    public func checkState() -> SMSStateEntity {
        repo.checkState()
    }
}
