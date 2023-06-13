
public struct SMSUseCase {
    public let getSMSUseCase: any GetSMSUseCaseProtocol
    public let checkSMSUseCase: any CheckSMSUseCaseProtocol
    
    public init(getSMSUseCase: any GetSMSUseCaseProtocol, checkSMSUseCase: any CheckSMSUseCaseProtocol) {
        self.getSMSUseCase = getSMSUseCase
        self.checkSMSUseCase = checkSMSUseCase
    }
}
