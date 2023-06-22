@testable import MEGA
import MEGADomainMock
import XCTest

class CallsSettingsViewModelTests: XCTestCase {

    func testAction_enableSoundNotifications() {
        let viewModel = CallsSettingsViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.callsSoundNotification: false]), analyticsEventUseCase: MockAnalyticsEventUseCase())
        viewModel.callsSoundNotificationPreference = true
        XCTAssert(viewModel.callsSoundNotificationPreference == true)
    }
    
    func testAction_disableSoundNotifications() {
        let viewModel = CallsSettingsViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.callsSoundNotification: true]), analyticsEventUseCase: MockAnalyticsEventUseCase())
        viewModel.callsSoundNotificationPreference = false
        XCTAssert(viewModel.callsSoundNotificationPreference == false )
    }
}
