@testable import MEGA
import MEGAAppPresentation
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPreference
import MEGASwift
import XCTest

final class AddPhoneNumberViewModelTests: XCTestCase {
    
    @MainActor
    func testAction_onViewReady_achievementSuccess() {
        let hideDontShowAgains = [true, false]
        
        let text = Strings.Localizable.GetFreeWhenYouAddYourPhoneNumber.thisMakesItEasierForYourContactsToFindYouOnMEGA(String.memoryStyleString(fromByteCount: 1000))
        
        for flag in hideDontShowAgains {
            let sut = AddPhoneNumberViewModel(router: MockAddPhoneNumberRouter(),
                                              achievementUseCase: MockAchievementUseCase(result: .bytes(of: 1000)),
                                              hideDontShowAgain: flag)
            
            test(viewModel: sut,
                 action: .onViewReady,
                 expectedCommands: [.configView(hideDontShowAgain: flag), .showAchievementStorage(text)])
        }
    }
    
    @MainActor
    func testAction_onViewReady_achievementError() {
        let errors: [AchievementErrorEntity] = [.generic, .achievementsDisabled]
        let message = Strings.Localizable.AddYourPhoneNumberToMEGA.thisMakesItEasierForYourContactsToFindYouOnMEGA
        
        errors.forEach { _ in
            let sut = AddPhoneNumberViewModel(router: MockAddPhoneNumberRouter(),
                                              achievementUseCase: MockAchievementUseCase(),
                                              hideDontShowAgain: false)
            test(viewModel: sut,
                 action: .onViewReady,
                 expectedCommands: [.configView(hideDontShowAgain: false),
                                    .loadAchievementError(message: message)])
        }
    }
    
    @MainActor func testAction_addPhoneNumber() {
        let router = MockAddPhoneNumberRouter()
        let sut = AddPhoneNumberViewModel(router: router,
                                          achievementUseCase: MockAchievementUseCase(),
                                          hideDontShowAgain: false)
        
        test(viewModel: sut, action: .addPhoneNumber, expectedCommands: [])
        XCTAssertEqual(router.goToVerification_calledTimes, 1)
    }
    
    @MainActor func testAction_notNow() {
        let router = MockAddPhoneNumberRouter()
        let sut = AddPhoneNumberViewModel(router: router,
                                          achievementUseCase: MockAchievementUseCase(),
                                          hideDontShowAgain: false)
        
        test(viewModel: sut, action: .notNow, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    @MainActor func testAction_notShowAddPhoneNumberAgain() {
        let router = MockAddPhoneNumberRouter()
        
        let preference = MockPreferenceUseCase()
        XCTAssertTrue(preference[PreferenceKeyEntity.dontShowAgainAddPhoneNumber.rawValue] == Optional<Bool>.none)
        
        let sut = AddPhoneNumberViewModel(router: router,
                                          achievementUseCase: MockAchievementUseCase(),
                                          preferenceUseCase: preference,
                                          hideDontShowAgain: false)
        
        test(viewModel: sut, action: .notShowAddPhoneNumberAgain, expectedCommands: [])
        XCTAssertEqual(router.dismiss_calledTimes, 1)
        XCTAssertTrue(preference[PreferenceKeyEntity.dontShowAgainAddPhoneNumber.rawValue] == true)
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
