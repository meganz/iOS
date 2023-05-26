import MEGADomain

public struct MockCheckSMSUseCase: CheckSMSUseCaseProtocol {
    private let checkCodeResult: Result<String, CheckSMSErrorEntity>
    private let sendToNumberResult: Result<String, CheckSMSErrorEntity>
    private let smsState: SMSStateEntity
    
    public init(checkCodeResult: Result<String, CheckSMSErrorEntity> = .failure(.generic),
                sendToNumberResult: Result<String, CheckSMSErrorEntity> = .failure(.generic),
                smsState: SMSStateEntity = .notAllowed) {
        self.checkCodeResult = checkCodeResult
        self.sendToNumberResult = sendToNumberResult
        self.smsState = smsState
    }
    
    public func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        completion(checkCodeResult)
    }
    
    public func sendVerification(toPhoneNumber: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        completion(sendToNumberResult)
    }
    
    public func checkState() -> SMSStateEntity {
        smsState
    }
}
