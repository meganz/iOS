@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class SMSVerificationViewModelTests: XCTestCase {
    
    @MainActor func testAction_onViewReady_unblockAccount() {
        let sms = SMSUseCase(getSMSUseCase: MockGetSMSUseCase(), checkSMSUseCase: MockCheckSMSUseCase())
        let sut = SMSVerificationViewModel(router: MockSMSVerificationViewRouter(),
                                           smsUseCase: sms,
                                           achievementUseCase: MockAchievementUseCase(),
                                           authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                           verificationType: .unblockAccount)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.configView(.unblockAccount)])
    }
    
    @MainActor
    func testAction_onViewReady_addNumber_achievementError() {
        let errors: [AchievementErrorEntity] = [.achievementsDisabled, .generic]
        let message = Strings.Localizable.AddYourPhoneNumberToMEGA.thisMakesItEasierForYourContactsToFindYouOnMEGA
        
        errors.forEach { _ in
            let sms = SMSUseCase(getSMSUseCase: MockGetSMSUseCase(), checkSMSUseCase: MockCheckSMSUseCase())
            
            let sut = SMSVerificationViewModel(router: MockSMSVerificationViewRouter(),
                                               smsUseCase: sms,
                                               achievementUseCase: MockAchievementUseCase(),
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                               verificationType: .addPhoneNumber)
            
            test(viewModel: sut,
                 action: .onViewReady,
                 expectedCommands: [.configView(.addPhoneNumber), .showLoadAchievementResult(.showError(message))])
        }
    }
    
    @MainActor func testAction_loadRegionCodes_success_hasCurrentRegion() {
        let region = RegionEntity(regionCode: "NZ", regionName: "New Zealand", callingCodes: ["64"])
        let list = RegionListEntity(currentRegion: region, allRegions: [region])
        let sms = SMSUseCase(getSMSUseCase: MockGetSMSUseCase(regionCodesResult: .success(list)),
                             checkSMSUseCase: MockCheckSMSUseCase())
        let sut = SMSVerificationViewModel(router: MockSMSVerificationViewRouter(),
                                           smsUseCase: sms,
                                           achievementUseCase: MockAchievementUseCase(),
                                           authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                           verificationType: .unblockAccount)
        
        test(viewModel: sut,
             action: SMSVerificationAction.loadRegionCodes,
             expectedCommands: [.startLoading,
                                .finishLoading,
                                .showRegion("New Zealand (+64)", callingCode: "+64")])
    }
    
    @MainActor func testAction_loadRegionCodes_success_doesNotHaveCurrentRegion() {
        let region = RegionEntity(regionCode: "NZ", regionName: "New Zealand", callingCodes: ["64"])
        let list = RegionListEntity(currentRegion: nil, allRegions: [region])
        let sms = SMSUseCase(getSMSUseCase: MockGetSMSUseCase(regionCodesResult: .success(list)),
                             checkSMSUseCase: MockCheckSMSUseCase())
        let sut = SMSVerificationViewModel(router: MockSMSVerificationViewRouter(),
                                           smsUseCase: sms,
                                           achievementUseCase: MockAchievementUseCase(),
                                           authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                           verificationType: .unblockAccount)
        
        test(viewModel: sut,
             action: SMSVerificationAction.loadRegionCodes,
             expectedCommands: [.startLoading, .finishLoading])
    }
    
    @MainActor func testAction_loadRegionCodes_error() {
        for error in GetSMSErrorEntity.allCases {
            let sms = SMSUseCase(getSMSUseCase: MockGetSMSUseCase(regionCodesResult: .failure(error)),
                                 checkSMSUseCase: MockCheckSMSUseCase())
            let sut = SMSVerificationViewModel(router: MockSMSVerificationViewRouter(),
                                               smsUseCase: sms,
                                               achievementUseCase: MockAchievementUseCase(),
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                               verificationType: .unblockAccount)
            test(viewModel: sut,
                 action: SMSVerificationAction.loadRegionCodes,
                 expectedCommands: [.startLoading, .finishLoading])
        }
    }
    
    @MainActor func testAction_showRegionList() {
        let router = MockSMSVerificationViewRouter()
        let sut = SMSVerificationViewModel(router: router,
                                           smsUseCase: SMSUseCase(getSMSUseCase: MockGetSMSUseCase(), checkSMSUseCase: MockCheckSMSUseCase()),
                                           achievementUseCase: MockAchievementUseCase(),
                                           authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                           verificationType: .unblockAccount)
        test(viewModel: sut, action: SMSVerificationAction.showRegionList, expectedCommands: [])
        XCTAssertEqual(router.goToRegionList_calledTimes, 1)
    }
    
    @MainActor func testAction_cancel() {
        let router = MockSMSVerificationViewRouter()
        let sut = SMSVerificationViewModel(router: router,
                                           smsUseCase: SMSUseCase(getSMSUseCase: MockGetSMSUseCase(), checkSMSUseCase: MockCheckSMSUseCase()),
                                           achievementUseCase: MockAchievementUseCase(),
                                           authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                           verificationType: .unblockAccount)
        test(viewModel: sut, action: SMSVerificationAction.cancel, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    @MainActor func testAction_sendCodeToPhoneNumber_success() {
        let sms = SMSUseCase(getSMSUseCase: MockGetSMSUseCase(),
                             checkSMSUseCase: MockCheckSMSUseCase(sendToNumberResult: .success("+64273142791")))
        let router = MockSMSVerificationViewRouter()
        let sut = SMSVerificationViewModel(router: router,
                                           smsUseCase: sms,
                                           achievementUseCase: MockAchievementUseCase(),
                                           authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                           verificationType: .unblockAccount)
        test(viewModel: sut,
             action: SMSVerificationAction.sendCodeToPhoneNumber("+64273142791", regionCode: "NZ"),
             expectedCommands: [.startLoading, .finishLoading])
            
        let routerExpectation = expectation(description: "goToVerificationCode")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            routerExpectation.fulfill()
        }
        
        wait(for: [routerExpectation], timeout: 0.2)
        XCTAssertEqual(router.goToVerification_codeCalledTimes, 1)
    }
    
    @MainActor func testAction_sendCodeToPhoneNumber_error() {
        let errorMessageDict: [CheckSMSErrorEntity: String] =
        [.reachedDailyLimit: Strings.Localizable.youHaveReachedTheDailyLimit,
         .alreadyVerifiedWithCurrentAccount: Strings.Localizable.yourAccountIsAlreadyVerified,
         .alreadyVerifiedWithAnotherAccount: Strings.Localizable.thisNumberIsAlreadyAssociatedWithAMegaAccount,
         .generic: Strings.Localizable.unknownError]
        
        for (error, message) in errorMessageDict {
            let sms = SMSUseCase(getSMSUseCase: MockGetSMSUseCase(),
                                 checkSMSUseCase: MockCheckSMSUseCase(sendToNumberResult: .failure(error)))
            let sut = SMSVerificationViewModel(router: MockSMSVerificationViewRouter(),
                                               smsUseCase: sms,
                                               achievementUseCase: MockAchievementUseCase(),
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                               verificationType: .unblockAccount)
            test(viewModel: sut,
                 action: SMSVerificationAction.sendCodeToPhoneNumber("+64273142791", regionCode: "NZ"),
                 expectedCommands: [.startLoading,
                                    .finishLoading,
                                    .sendCodeToPhoneNumberError(message: message)])
        }
    }
    
    @MainActor func testAction_sendCodeToPhoneNumber_wrongFormatError() {
        let errorMessageDict: [CheckSMSErrorEntity: String] =
        [.wrongFormat: Strings.Localizable.pleaseEnterAValidPhoneNumber]
        
        for (error, message) in errorMessageDict {
            let sms = SMSUseCase(getSMSUseCase: MockGetSMSUseCase(),
                                 checkSMSUseCase: MockCheckSMSUseCase(sendToNumberResult: .failure(error)))
            let sut = SMSVerificationViewModel(router: MockSMSVerificationViewRouter(),
                                               smsUseCase: sms,
                                               achievementUseCase: MockAchievementUseCase(),
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true),
                                               verificationType: .unblockAccount)
            test(viewModel: sut,
                 action: SMSVerificationAction.sendCodeToPhoneNumber("12345", regionCode: "NZ"),
                 expectedCommands: [.startLoading,
                                    .finishLoading,
                                    .sendCodeToPhoneNumberError(message: message)])
        }
    }
}

final class MockSMSVerificationViewRouter: SMSVerificationViewRouting {
    var dismiss_calledTimes = 0
    var goToRegionList_calledTimes = 0
    var goToVerification_codeCalledTimes = 0
    
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
