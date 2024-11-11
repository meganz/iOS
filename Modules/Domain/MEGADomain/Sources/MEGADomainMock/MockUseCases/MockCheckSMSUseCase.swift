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
    
    public func checkVerificationCode(_ code: String) async throws -> String {
        try checkCodeResult.get()
    }
    
    public func sendVerification(toPhoneNumber: String) async throws -> String {
        try sendToNumberResult.get()
    }
    
    public func checkState() -> SMSStateEntity {
        smsState
    }
}
