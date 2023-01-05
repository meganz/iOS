
public struct SMSUseCase {
    public let getSMSUseCase: GetSMSUseCaseProtocol
    public let checkSMSUseCase: CheckSMSUseCaseProtocol
    
    public init(getSMSUseCase: GetSMSUseCaseProtocol, checkSMSUseCase: CheckSMSUseCaseProtocol) {
        self.getSMSUseCase = getSMSUseCase
        self.checkSMSUseCase = checkSMSUseCase
    }
}
