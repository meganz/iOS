import XCTest
@testable import MEGA
import MEGADomainMock

class CallsSettingsViewModelTests: XCTestCase {

    func testAction_enableSoundNotifications() {
        let viewModel = CallsSettingsViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.callsSoundNotification: false]))
        viewModel.callsSoundNotificationPreference = true
        XCTAssert(viewModel.callsSoundNotificationPreference == true)
    }
    
    func testAction_disableSoundNotifications() {
        let viewModel = CallsSettingsViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.callsSoundNotification: true]))
        viewModel.callsSoundNotificationPreference = false
        XCTAssert(viewModel.callsSoundNotificationPreference == false )
    }
}
