@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class VerificationCodeViewModelTests: XCTestCase {
    private let testPhoneNumber = "+64272320000"
    private let formattedPhoneNumber = "+64 27 232 0000"
    private let regionCode = "NZ"
    
    @MainActor private func makeSUT(
        router: some VerificationCodeViewRouting = MockVerificationCodeViewRouter(),
        checkSMSUseCase: some CheckSMSUseCaseProtocol = MockCheckSMSUseCase(),
        authUseCase: some AuthUseCaseProtocol = MockAuthUseCase(isUserLoggedIn: true),
        verificationType: SMSVerificationType,
        phoneNumber: String = "",
        regionCode: RegionCode = ""
    ) -> VerificationCodeViewModel {
        VerificationCodeViewModel(
            router: router,
            checkSMSUseCase: checkSMSUseCase,
            authUseCase: authUseCase,
            verificationType: verificationType,
            phoneNumber: phoneNumber,
            regionCode: regionCode
        )
    }

    @MainActor func testAction_onViewReady_addPhoneNumber() {
        let sut = makeSUT(
            verificationType: .addPhoneNumber,
            phoneNumber: testPhoneNumber,
            regionCode: regionCode
        )
        test(
            viewModel: sut,
            action: .onViewReady,
            expectedCommands: [.configView(phoneNumber: formattedPhoneNumber, screenTitle: Strings.Localizable.addPhoneNumber)]
        )
    }
    
    @MainActor func testAction_onViewReady_unblockAccount() {
        let sut = makeSUT(
            verificationType: .unblockAccount,
            phoneNumber: testPhoneNumber,
            regionCode: regionCode
        )
        test(
            viewModel: sut,
            action: .onViewReady,
            expectedCommands: [.configView(phoneNumber: formattedPhoneNumber, screenTitle: Strings.Localizable.verifyYourAccount)]
        )
    }

    @MainActor func testAction_resendCode() {
        let router = MockVerificationCodeViewRouter()
        let sut = makeSUT(router: router, verificationType: .addPhoneNumber)
        
        test(
            viewModel: sut,
            action: .resendCode,
            expectedCommands: []
        )
        XCTAssertEqual(router.goBack_calledTimes, 1)
    }
    
    @MainActor func testAction_didCheckCodeSucceeded_addPhoneNumber() {
        let router = MockVerificationCodeViewRouter()
        let sut = makeSUT(
            router: router,
            verificationType: .addPhoneNumber
        )
        
        test(
            viewModel: sut,
            action: .didCheckCodeSucceeded,
            expectedCommands: []
        )
        XCTAssertEqual(router.phoneNumberVerified_calledTimes, 1)
    }
    
    @MainActor func testAction_didCheckCodeSucceeded_unblockAccount_notLogin() {
        let router = MockVerificationCodeViewRouter()
        let sut = makeSUT(
            router: router,
            verificationType: .unblockAccount
        )
        
        test(
            viewModel: sut,
            action: .didCheckCodeSucceeded,
            expectedCommands: []
        )
        XCTAssertEqual(router.phoneNumberVerified_calledTimes, 1)
        XCTAssertEqual(router.goToOnboarding_calledTimes, 1)
    }
    
    @MainActor func testAction_didCheckCodeSucceeded_unblockAccount_login() {
        let router = MockVerificationCodeViewRouter()
        let authUseCase = MockAuthUseCase(
            loginSessionId: "mockSessionId",
            isUserLoggedIn: true
        )
        let sut = makeSUT(
            router: router,
            authUseCase: authUseCase,
            verificationType: .unblockAccount
        )
        
        test(
            viewModel: sut,
            action: .didCheckCodeSucceeded,
            expectedCommands: []
        )
        XCTAssertEqual(router.phoneNumberVerified_calledTimes, 1)
    }
    
    @MainActor func testAction_checkVerificationCode_success() async {
        let sut = makeSUT(
            checkSMSUseCase: MockCheckSMSUseCase(checkCodeResult: .success("")),
            verificationType: .unblockAccount
        )
        
        await test(
            viewModel: sut,
            action: .checkVerificationCode(""),
            expectedCommands: [.startLoading, .checkCodeSucceeded, .finishLoading]
        )
    }

    @MainActor func testAction_checkVerificationCode_error() async {
        let errorMessageDict: [CheckSMSErrorEntity: String] = [
            .reachedDailyLimit: Strings.Localizable.youHaveReachedTheDailyLimit,
            .codeDoesNotMatch: Strings.Localizable.theVerificationCodeDoesnTMatch,
            .alreadyVerifiedWithAnotherAccount: Strings.Localizable.yourAccountIsAlreadyVerified,
            .generic: Strings.Localizable.unknownError
        ]

        for (error, message) in errorMessageDict {
            let sut = makeSUT(
                checkSMSUseCase: MockCheckSMSUseCase(checkCodeResult: .failure(error)),
                verificationType: .unblockAccount
            )
            
            await test(
                viewModel: sut,
                action: .checkVerificationCode(""),
                expectedCommands: [.startLoading, .checkCodeError(message: message), .finishLoading]
            )
        }
    }
}

final class MockVerificationCodeViewRouter: VerificationCodeViewRouting {
    var goBack_calledTimes = 0
    var goToOnboarding_calledTimes = 0
    var phoneNumberVerified_calledTimes = 0
    
    public nonisolated init() {}
    
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
