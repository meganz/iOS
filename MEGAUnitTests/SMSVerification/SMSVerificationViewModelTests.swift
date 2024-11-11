@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class SMSVerificationViewModelTests: XCTestCase {
    private let testPhoneNumber = "+64273142791"
    private let regionCode = "NZ"
    private let regionName = "New Zealand"
    private let callingCode = "+64"
    private let achievementErrorMessage = Strings.Localizable.AddYourPhoneNumberToMEGA.thisMakesItEasierForYourContactsToFindYouOnMEGA
    
    @MainActor private func makeSUT(
        router: some SMSVerificationViewRouting = MockSMSVerificationViewRouter(),
        smsUseCase: SMSUseCase = SMSUseCase(getSMSUseCase: MockGetSMSUseCase(),
                                            checkSMSUseCase: MockCheckSMSUseCase()),
        achievementUseCase: some AchievementUseCaseProtocol = MockAchievementUseCase(),
        authUseCase: some AuthUseCaseProtocol = MockAuthUseCase(isUserLoggedIn: true),
        verificationType: SMSVerificationType
    ) -> SMSVerificationViewModel {
        SMSVerificationViewModel(
            router: router,
            smsUseCase: smsUseCase,
            achievementUseCase: achievementUseCase,
            authUseCase: authUseCase,
            verificationType: verificationType
        )
    }
    
    private func makeRegion(_ callingCodes: [String] = ["64"]) -> RegionEntity {
        RegionEntity(
            regionCode: regionCode,
            regionName: regionName,
            callingCodes: callingCodes
        )
    }
    
    @MainActor func testAction_onViewReady_unblockAccount() {
        let sut = makeSUT(verificationType: .unblockAccount)
        test(
            viewModel: sut,
            action: .onViewReady,
            expectedCommands: [.configView(.unblockAccount)]
        )
    }
    
    @MainActor func testAction_onViewReady_addNumber_achievementError() {
        let errors: [AchievementErrorEntity] = [.achievementsDisabled, .generic]
        
        errors.forEach { _ in
            let sut = makeSUT(verificationType: .addPhoneNumber)
            test(
                viewModel: sut,
                action: .onViewReady,
                expectedCommands: [.configView(.addPhoneNumber), .showLoadAchievementResult(.showError(achievementErrorMessage))]
            )
        }
    }
    
    @MainActor func testAction_loadRegionCodes_success_hasCurrentRegion() async {
        let region = makeRegion()
        let list = RegionListEntity(
            currentRegion: region,
            allRegions: [region]
        )
        let sms = SMSUseCase(
            getSMSUseCase: MockGetSMSUseCase(regionCodesResult: .success(list)),
            checkSMSUseCase: MockCheckSMSUseCase()
        )
        let sut = makeSUT(
            smsUseCase: sms,
            verificationType: .unblockAccount
        )
        
        await test(
            viewModel: sut,
            action: .loadRegionCodes,
            expectedCommands: [
                .startLoading,
                .showRegion("\(regionName) (\(callingCode))", callingCode: callingCode),
                .finishLoading
            ]
        )
    }
    
    @MainActor func testAction_loadRegionCodes_success_doesNotHaveCurrentRegion() {
        let list = RegionListEntity(
            currentRegion: nil,
            allRegions: [makeRegion([callingCode])]
        )
        let sms = SMSUseCase(
            getSMSUseCase: MockGetSMSUseCase(regionCodesResult: .success(list)),
            checkSMSUseCase: MockCheckSMSUseCase()
        )
        let sut = makeSUT(
            smsUseCase: sms,
            verificationType: .unblockAccount
        )
        
        test(
            viewModel: sut,
            action: .loadRegionCodes,
            expectedCommands: [.startLoading, .finishLoading]
        )
    }
    
    @MainActor func testAction_loadRegionCodes_error() {
        for error in GetSMSErrorEntity.allCases {
            let sms = SMSUseCase(
                getSMSUseCase: MockGetSMSUseCase(regionCodesResult: .failure(error)),
                checkSMSUseCase: MockCheckSMSUseCase()
            )
            let sut = makeSUT(
                smsUseCase: sms,
                verificationType: .unblockAccount
            )
            test(
                viewModel: sut,
                action: .loadRegionCodes,
                expectedCommands: [.startLoading, .finishLoading]
            )
        }
    }
    
    @MainActor func testAction_showRegionList() {
        let router = MockSMSVerificationViewRouter()
        let sut = makeSUT(
            router: router,
            verificationType: .unblockAccount
        )
        
        test(
            viewModel: sut,
            action: .showRegionList,
            expectedCommands: []
        )
        XCTAssertEqual(router.goToRegionList_calledTimes, 1)
    }
    
    @MainActor func testAction_cancel() {
        let router = MockSMSVerificationViewRouter()
        let sut = makeSUT(
            router: router,
            verificationType: .unblockAccount
        )
        
        test(
            viewModel: sut,
            action: .cancel,
            expectedCommands: []
        )
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    @MainActor func testAction_sendCodeToPhoneNumber_success() async throws {
        let sms = SMSUseCase(
            getSMSUseCase: MockGetSMSUseCase(),
            checkSMSUseCase: MockCheckSMSUseCase(sendToNumberResult: .success(testPhoneNumber))
        )
        let router = MockSMSVerificationViewRouter()
        let sut = makeSUT(
            router: router,
            smsUseCase: sms,
            verificationType: .unblockAccount
        )
        
        await test(
            viewModel: sut,
            action: .sendCodeToPhoneNumber(testPhoneNumber, regionCode: regionCode),
            expectedCommands: [.startLoading, .finishLoading]
        )
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(router.goToVerification_codeCalledTimes, 1)
    }
    
    @MainActor func testAction_sendCodeToPhoneNumber_error() async {
        let errorMessageDict: [CheckSMSErrorEntity: String] = [
            .reachedDailyLimit: Strings.Localizable.youHaveReachedTheDailyLimit,
            .alreadyVerifiedWithCurrentAccount: Strings.Localizable.yourAccountIsAlreadyVerified,
            .alreadyVerifiedWithAnotherAccount: Strings.Localizable.thisNumberIsAlreadyAssociatedWithAMegaAccount,
            .generic: Strings.Localizable.unknownError
        ]
        
        for (error, message) in errorMessageDict {
            let sms = SMSUseCase(
                getSMSUseCase: MockGetSMSUseCase(),
                checkSMSUseCase: MockCheckSMSUseCase(sendToNumberResult: .failure(error))
            )
            let sut = makeSUT(
                smsUseCase: sms,
                verificationType: .unblockAccount
            )
            await test(
                viewModel: sut,
                action: .sendCodeToPhoneNumber(testPhoneNumber, regionCode: regionCode),
                expectedCommands: [.startLoading, .sendCodeToPhoneNumberError(message: message), .finishLoading]
            )
        }
    }
    
    @MainActor func testAction_sendCodeToPhoneNumber_wrongFormatError() async {
        let errorMessageDict: [CheckSMSErrorEntity: String] = [
            .wrongFormat: Strings.Localizable.pleaseEnterAValidPhoneNumber
        ]
        
        for (error, message) in errorMessageDict {
            let sms = SMSUseCase(
                getSMSUseCase: MockGetSMSUseCase(),
                checkSMSUseCase: MockCheckSMSUseCase(sendToNumberResult: .failure(error))
            )
            let sut = makeSUT(
                smsUseCase: sms,
                verificationType: .unblockAccount
            )
            await test(
                viewModel: sut,
                action: .sendCodeToPhoneNumber("12345", regionCode: regionCode),
                expectedCommands: [.startLoading, .finishLoading, .sendCodeToPhoneNumberError(message: message)]
            )
        }
    }
}

final class MockSMSVerificationViewRouter: SMSVerificationViewRouting {
    var dismiss_calledTimes = 0
    var goToRegionList_calledTimes = 0
    var goToVerification_codeCalledTimes = 0
    
    public nonisolated init() {}
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func goToRegionList(_ list: [SMSRegion], onRegionSelected: @escaping (SMSRegion) -> Void) {
        goToRegionList_calledTimes += 1
    }
    
    func goToVerificationCode(forPhoneNumber number: String, withRegionCode regionCode: RegionCode) {
        goToVerification_codeCalledTimes += 1
    }
}
