import Foundation
import PhoneNumberKit

// MARK: - Use case protocol -
protocol CheckSMSUseCaseProtocol {
    func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void)
    func sendVerification(toPhoneNumber number: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void)
    func checkState() -> SMSStateEntity
}

// MARK: - Use case implementation -
struct CheckSMSUseCase<T: SMSRepositoryProtocol>: CheckSMSUseCaseProtocol {
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        repo.checkVerificationCode(code, completion: completion)
    }

    func sendVerification(toPhoneNumber number: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        let formattedNumber: String
        do {
            let numberKit = PhoneNumberKit()
            let parsedNumber = try numberKit.parse(number)
            formattedNumber = numberKit.format(parsedNumber, toType: .e164)
        } catch {
            completion(.failure(.wrongFormat))
            return
        }
        
        repo.sendVerification(toPhoneNumber: formattedNumber, completion: completion)
    }
    
    func checkState() -> SMSStateEntity {
        repo.checkState()
    }
}

