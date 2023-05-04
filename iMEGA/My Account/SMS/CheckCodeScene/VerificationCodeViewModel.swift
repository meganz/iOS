import Foundation
import PhoneNumberKit
import MEGADomain
import MEGAPresentation

enum VerificationCodeAction: ActionType {
    case onViewReady
    case resendCode
    case checkVerificationCode(String)
    case didCheckCodeSucceeded
}

protocol VerificationCodeViewRouting: Routing {
    func goBack()
    func goToOnboarding()
    func phoneNumberVerified()
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
            return Strings.Localizable.addPhoneNumber
        case .unblockAccount:
            return Strings.Localizable.verifyYourAccount
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
                    message = Strings.Localizable.youHaveReachedTheDailyLimit
                case .codeDoesNotMatch:
                    message = Strings.Localizable.theVerificationCodeDoesnTMatch
                case .alreadyVerifiedWithAnotherAccount:
                    message = Strings.Localizable.yourAccountIsAlreadyVerified
                default:
                    message = Strings.Localizable.unknownError
                }
                self.invokeCommand?(.checkCodeError(message: message))
            }
        }
    }
    
    private func didCheckCodeSucceeded() {
        router.phoneNumberVerified()

        guard verificationType == .unblockAccount else { return }
        
        guard let sessionId = authUseCase.sessionId() else {
            router.goToOnboarding()
            return
        }
        
        Task {
            try await authUseCase.login(sessionId: sessionId)
        }
    }
}
