import Foundation
import PhoneNumberKit

enum VerificationCodeAction: ActionType {
    case onViewReady
    case resendCode
    case checkVerificationCode(String)
    case didCheckCodeSucceeded
}

protocol VerificationCodeViewRouting: Routing {
    func dismiss()
    func goBack()
    func goToOnboarding()
}

struct VerificationCodeViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case startLoading
        case finishLoading
        case configView(phoneNumber: String, screenTitle: String)
        case checkCodeError(message: String)
        case checkCodeSucceeded
    }
    
    // MARK: - Private properties
    private let checkSMSUseCase: CheckSMSUseCaseProtocol
    private let authUseCase: AuthUseCaseProtocol
    private let verificationType: SMSVerificationType
    private let router: VerificationCodeViewRouting
    private let phoneNumber: String
    private var screenTitle: String {
        switch verificationType {
        case .addPhoneNumber:
            return NSLocalizedString("Add Phone Number", comment: "")
        case .unblockAccount:
            return NSLocalizedString("Verify Your Account", comment: "")
        }
    }
    
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: VerificationCodeViewRouting,
         checkSMSUseCase: CheckSMSUseCaseProtocol,
         authUseCase: AuthUseCaseProtocol,
         verificationType: SMSVerificationType,
         phoneNumber: String) {
        self.router = router
        self.checkSMSUseCase = checkSMSUseCase
        self.authUseCase = authUseCase
        self.verificationType = verificationType
        self.phoneNumber = phoneNumber
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: VerificationCodeAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(phoneNumber: formatNumber(phoneNumber), screenTitle: screenTitle))
        case .checkVerificationCode(let code):
            checkVerificationCode(code)
        case .resendCode:
            router.goBack()
        case .didCheckCodeSucceeded:
            didCheckCodeSucceeded()
        }
    }
    
    private func formatNumber(_ number: String) -> String {
        do {
            let numberKit = PhoneNumberKit()
            return numberKit.format(try numberKit.parse(number), toType: .international)
        } catch {
            return number
        }
    }
    
    // MARK: - Check code
    private func checkVerificationCode(_ code: String) {
        invokeCommand?(.startLoading)
        checkSMSUseCase.checkVerificationCode(code) {
            self.invokeCommand?(.finishLoading)
            switch $0 {
            case .success:
                self.invokeCommand?(.checkCodeSucceeded)
            case .failure(let error):
                var message: String
                switch error {
                case .reachedDailyLimit:
                    message = NSLocalizedString("You have reached the daily limit", comment: "")
                case .codeDoesNotMatch:
                    message = NSLocalizedString("The verification code doesn't match.", comment: "")
                case .alreadyVerifiedWithAnotherAccount:
                    message = NSLocalizedString("Your account is already verified", comment: "")
                default:
                    message = NSLocalizedString("Unknown error", comment: "")
                }
                self.invokeCommand?(.checkCodeError(message: message))
            }
        }
    }
    
    private func didCheckCodeSucceeded() {
        router.dismiss()
        
        guard verificationType == .unblockAccount else { return }
        
        guard let sessionId = authUseCase.sessionId() else {
            router.goToOnboarding()
            return
        }
        
        authUseCase.login(sessionId: sessionId, delegate: MEGALoginRequestDelegate())
    }
}
