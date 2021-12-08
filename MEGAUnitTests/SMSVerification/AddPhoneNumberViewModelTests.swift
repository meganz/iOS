import XCTest
@testable import MEGA

final class AddPhoneNumberViewModelTests: XCTestCase {
    
    func testAction_onViewReady_achievementSuccess() {
        let hideDontShowAgains = [true, false]
        
        let text = Strings.Localizable.GetFreeWhenYouAddYourPhoneNumber.thisMakesItEasierForYourContactsToFindYouOnMEGA(Helper.memoryStyleString(fromByteCount: 1000))

        for flag in hideDontShowAgains {
            let sut = AddPhoneNumberViewModel(router: MockAddPhoneNumberRouter(),
                                              achievementUseCase: MockAchievementUseCase(result: .success(.bytes(of: 1000))),
                                              hideDontShowAgain: flag)
            
            test(viewModel: sut,
                 action: .onViewReady,
                 expectedCommands: [.configView(hideDontShowAgain: flag), .showAchievementStorage(text)])
        }
    }
    
    func testAction_onViewReady_achievementError() {
        let errors: [AchievementErrorEntity] = [.generic, .achievementsDisabled]
        let message = Strings.Localizable.AddYourPhoneNumberToMEGA.thisMakesItEasierForYourContactsToFindYouOnMEGA
        
        for error in errors {
            let sut = AddPhoneNumberViewModel(router: MockAddPhoneNumberRouter(),
                                              achievementUseCase: MockAchievementUseCase(result: .failure(error)),
                                              hideDontShowAgain: false)
            test(viewModel: sut,
                 action: .onViewReady,
                 expectedCommands: [.configView(hideDontShowAgain: false),
                                    .loadAchievementError(message: message)])
        }
    }
    
    func testAction_addPhoneNumber() {
        let router = MockAddPhoneNumberRouter()
        let sut = AddPhoneNumberViewModel(router: router,
                                          achievementUseCase: MockAchievementUseCase(result: .failure(.generic)),
                                          hideDontShowAgain: false)
        
        test(viewModel: sut, action: .addPhoneNumber, expectedCommands: [])
        XCTAssertEqual(router.goToVerification_calledTimes, 1)
    }
    
    func testAction_notNow() {
        let router = MockAddPhoneNumberRouter()
        let sut = AddPhoneNumberViewModel(router: router,
                                          achievementUseCase: MockAchievementUseCase(result: .failure(.generic)),
                                          hideDontShowAgain: false)
        
        test(viewModel: sut, action: .notNow, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    func testAction_notShowAddPhoneNumberAgain() {
        let router = MockAddPhoneNumberRouter()
        
        let preference = MockPreferenceUseCase()
        XCTAssertTrue(preference[.dontShowAgainAddPhoneNumber] == Optional<Bool>.none)
        
        let sut = AddPhoneNumberViewModel(router: router,
                                          achievementUseCase: MockAchievementUseCase(result: .failure(.generic)),
                                          preferenceUseCase: preference,
                                          hideDontShowAgain: false)
        
        test(viewModel: sut, action: .notShowAddPhoneNumberAgain, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
        XCTAssertTrue(preference[.dontShowAgainAddPhoneNumber] == true)
    }
}

final class MockAddPhoneNumberRouter: AddPhoneNumberRouting {
    var goToVerification_calledTimes = 0
    var dismiss_calledTimes = 0
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func goToVerification() {
        goToVerification_calledTimes += 1
    }
}
