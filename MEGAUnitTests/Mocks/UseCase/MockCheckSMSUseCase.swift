@testable import MEGA

struct MockCheckSMSUseCase: CheckSMSUseCaseProtocol {
    var checkCodeResult: Result<String, CheckSMSErrorEntity> = .failure(.generic)
    var sendToNumberResult: Result<String, CheckSMSErrorEntity> = .failure(.generic)
    var smsState: SMSStateEntity = .notAllowed
    
    func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        completion(checkCodeResult)
    }
    
    func sendVerification(toPhoneNumber number: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        completion(sendToNumberResult)
    }
    
    func checkState() -> SMSStateEntity {
        smsState
    }
}
