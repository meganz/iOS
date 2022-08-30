import XCTest
@testable import MEGA
import MEGADomainMock

class CallsSettingsViewModelTests: XCTestCase {

    func testAction_enableSoundNotifications() {
        let viewModel = CallsSettingsViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.callsSoundNotification: false]), statsUseCase: MockMeetingStatsUseCase())
        viewModel.callsSoundNotificationPreference = true
        XCTAssert(viewModel.callsSoundNotificationPreference == true)
    }
    
    func testAction_disableSoundNotifications() {
        let viewModel = CallsSettingsViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [.callsSoundNotification: true]), statsUseCase: MockMeetingStatsUseCase())
        viewModel.callsSoundNotificationPreference = false
        XCTAssert(viewModel.callsSoundNotificationPreference == false )
    }
}
