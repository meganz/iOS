@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class VerificationCodeViewModelTests: XCTestCase {
    
    @MainActor func testAction_onViewReady_addPhoneNumber() {
        let sut = VerificationCodeViewModel(router: MockVerificationCodeViewRouter(),
                                            checkSMSUseCase: MockCheckSMSUseCase(),
                                            authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                            verificationType: .addPhoneNumber,
                                            phoneNumber: "+64272320000",
                                            regionCode: "NZ")
        
        test(viewModel: sut,
             action: VerificationCodeAction.onViewReady,
             expectedCommands: [.configView(phoneNumber: "+64 27 232 0000", screenTitle: Strings.Localizable.addPhoneNumber)])
    }
    
    @MainActor func testAction_onViewReady_unblockAccount() {
        let sut = VerificationCodeViewModel(router: MockVerificationCodeViewRouter(),
                                            checkSMSUseCase: MockCheckSMSUseCase(),
                                            authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                            verificationType: .unblockAccount,
                                            phoneNumber: "+64272320000",
                                            regionCode: "NZ")
        
        test(viewModel: sut,
             action: VerificationCodeAction.onViewReady,
             expectedCommands: [.configView(phoneNumber: "+64 27 232 0000", screenTitle: Strings.Localizable.verifyYourAccount)])
    }

    @MainActor func testAction_resendCode() {
        let router = MockVerificationCodeViewRouter()
        let sut = VerificationCodeViewModel(router: router,
                                            checkSMSUseCase: MockCheckSMSUseCase(),
                                            authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                            verificationType: .addPhoneNumber,
                                            phoneNumber: "",
                                            regionCode: "")
        
        test(viewModel: sut, action: VerificationCodeAction.resendCode, expectedCommands: [])
        XCTAssertEqual(router.goBack_calledTimes, 1)
    }
    
    @MainActor func testAction_didCheckCodeSucceeded_addPhoneNumber() {
        let router = MockVerificationCodeViewRouter()
        let sut = VerificationCodeViewModel(router: router,
                                            checkSMSUseCase: MockCheckSMSUseCase(),
                                            authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                            verificationType: .addPhoneNumber,
                                            phoneNumber: "",
                                            regionCode: "")
        
        test(viewModel: sut, action: VerificationCodeAction.didCheckCodeSucceeded, expectedCommands: [])
        XCTAssertEqual(router.phoneNumberVerified_calledTimes, 1)
    }
    
    @MainActor func testAction_didCheckCodeSucceeded_unblockAccount_notLogin() {
        let router = MockVerificationCodeViewRouter()
        let sut = VerificationCodeViewModel(router: router,
                                            checkSMSUseCase: MockCheckSMSUseCase(),
                                            authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                            verificationType: .unblockAccount,
                                            phoneNumber: "",
                                            regionCode: "")
        
        test(viewModel: sut, action: VerificationCodeAction.didCheckCodeSucceeded, expectedCommands: [])
        XCTAssertEqual(router.phoneNumberVerified_calledTimes, 1)
        XCTAssertEqual(router.goToOnboarding_calledTimes, 1)
    }
    
    @MainActor func testAction_didCheckCodeSucceeded_unblockAccount_login() {
        let router = MockVerificationCodeViewRouter()
        let sut = VerificationCodeViewModel(router: router,
                                            checkSMSUseCase: MockCheckSMSUseCase(),
                                            authUseCase: MockAuthUseCase(loginSessionId: "mockSessionId",
                                                                         isUserLoggedIn: true),
                                            verificationType: .unblockAccount,
                                            phoneNumber: "",
                                            regionCode: "")
        
        test(viewModel: sut, action: VerificationCodeAction.didCheckCodeSucceeded, expectedCommands: [])
        XCTAssertEqual(router.phoneNumberVerified_calledTimes, 1)
    }
    
    @MainActor func testAction_checkVerificationCode_success() {
        let sut = VerificationCodeViewModel(router: MockVerificationCodeViewRouter(),
                                            checkSMSUseCase: MockCheckSMSUseCase(checkCodeResult: .success("")),
                                            authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                            verificationType: .unblockAccount,
                                            phoneNumber: "",
                                            regionCode: "")
        
        test(viewModel: sut,
             action: VerificationCodeAction.checkVerificationCode(""),
             expectedCommands: [.startLoading,
                                .finishLoading,
                                .checkCodeSucceeded])
    }
    
    @MainActor func testAction_checkVerificationCode_error() {
        let errorMessageDict: [CheckSMSErrorEntity: String] =
        [.reachedDailyLimit: Strings.Localizable.youHaveReachedTheDailyLimit,
         .codeDoesNotMatch: Strings.Localizable.theVerificationCodeDoesnTMatch,
         .alreadyVerifiedWithAnotherAccount: Strings.Localizable.yourAccountIsAlreadyVerified,
         .generic: Strings.Localizable.unknownError]
        
        for (error, message) in errorMessageDict {
            let sut = VerificationCodeViewModel(router: MockVerificationCodeViewRouter(),
                                                checkSMSUseCase: MockCheckSMSUseCase(checkCodeResult: .failure(error)),
                                                authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                                verificationType: .unblockAccount,
                                                phoneNumber: "",
                                                regionCode: "")
            
            test(viewModel: sut,
                 action: VerificationCodeAction.checkVerificationCode(""),
                 expectedCommands: [.startLoading,
                                    .finishLoading,
                                    .checkCodeError(message: message)])
        }
    }
}

final class MockVerificationCodeViewRouter: VerificationCodeViewRouting {
    var goBack_calledTimes = 0
    var goToOnboarding_calledTimes = 0
    var phoneNumberVerified_calledTimes = 0
    
    func goBack() {
        goBack_calledTimes += 1
    }
    
    func goToOnboarding() {
        goToOnboarding_calledTimes += 1
    }

    func phoneNumberVerified() {
        phoneNumberVerified_calledTimes += 1
    }
}
