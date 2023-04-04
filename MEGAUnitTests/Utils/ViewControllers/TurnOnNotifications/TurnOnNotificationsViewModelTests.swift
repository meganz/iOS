import XCTest
@testable import MEGA
import MEGADomainMock

final class TurnOnNotificationsViewModelTests: XCTestCase {
    
    let mockRouter = MockTurnOnNotificationsViewRouter()
    let mockPreference = MockPreferenceUseCase()
    
    func testAction_onViewLoaded_configView() {
        let sut = TurnOnNotificationsViewModel(router: mockRouter,
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        sut.dispatch(.onViewLoaded)
        
        let title = Strings.Localizable.Dialog.TurnOnNotifications.Label.title
        let description = Strings.Localizable.Dialog.TurnOnNotifications.Label.description
        let stepOne = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepOne
        let stepTwo = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepTwo
        let stepThree = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepThree
        let stepFour = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepFour

        let expectedNotificationsModel = TurnOnNotificationsModel(headerImageName: "groupChat",
                                                          title: title,
                                                          description: description,
                                                          stepOneImageName: Asset.Images.WarningTurnonNotifications.openSettings.name,
                                                          stepOne: stepOne,
                                                          stepTwoImageName: Asset.Images.WarningTurnonNotifications.tapNotifications.name,
                                                          stepTwo: stepTwo,
                                                          stepThreeImageName: Asset.Images.WarningTurnonNotifications.tapMega.name,
                                                          stepThree: stepThree,
                                                          stepFourImageName: Asset.Images.WarningTurnonNotifications.allowNotifications.name,
                                                          stepFour: stepFour,
                                                          openSettingsTitle: Strings.Localizable.Dialog.TurnOnNotifications.Button.primary,
                                                          dismissTitle: Strings.Localizable.dismiss)
        test(viewModel: sut, action: .onViewLoaded, expectedCommands: [.configView(expectedNotificationsModel)])
    }
    
    func testAction_openSettings() {
        let sut = TurnOnNotificationsViewModel(router: mockRouter,
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: sut, action: .openSettings, expectedCommands: [])
        XCTAssertEqual(mockRouter.openSettings_calledTimes, 1)
    }
    
    func testAction_dismiss() {
        let sut = TurnOnNotificationsViewModel(router: mockRouter,
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: sut, action: .dismiss, expectedCommands: [])
        XCTAssertEqual(mockRouter.dismiss_calledTimes, 1)
    }
    
    func testShoudlShowTurnOnNotifications_moreThanSevenDaysHasPassed() {
        mockPreference.dict[.lastDateTurnOnNotificationsShowed] = Date.init(timeIntervalSince1970: 0)
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: false))
        XCTAssertFalse(sut.shouldShowTurnOnNotifications())
    }
    
    func testShoudlShowTurnOnNotifications_moreThanSevenDaysHasPassed_userLoggedIn() {
        mockPreference.dict[.lastDateTurnOnNotificationsShowed] = Date.init(timeIntervalSince1970: 0)
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        XCTAssertTrue(sut.shouldShowTurnOnNotifications())
    }
    
    func testShoudlShowTurnOnNotifications_lessThanSevenDaysHasPassed() {
        mockPreference.dict[.lastDateTurnOnNotificationsShowed] = Date()
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        XCTAssertFalse(sut.shouldShowTurnOnNotifications())
    }
    
    func testShoudlShowTurnOnNotifications_equalOrMoreThanThreeTimesShown() {
        mockPreference.dict[.timesTurnOnNotificationsShowed] = 3
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        XCTAssertFalse(sut.shouldShowTurnOnNotifications())
    }
    
    func testShoudlShowTurnOnNotifications_lessThanThreeTimesShown() {
        mockPreference.dict[.timesTurnOnNotificationsShowed] = 2
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: false))
        XCTAssertFalse(sut.shouldShowTurnOnNotifications())
    }
    
    func testShoudlShowTurnOnNotifications_lessThanThreeTimesShown_userLoggedI() {
        mockPreference.dict[.timesTurnOnNotificationsShowed] = 2
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        XCTAssertTrue(sut.shouldShowTurnOnNotifications())
    }
}

final class MockTurnOnNotificationsViewRouter: TurnOnNotificationsViewRouting {
    var openSettings_calledTimes = 0
    var dismiss_calledTimes = 0
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func openSettings() {
        openSettings_calledTimes += 1
    }
}
