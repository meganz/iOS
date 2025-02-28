import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

@testable import Settings

@Suite("NotificationSettingsViewModelTestSuit")
@MainActor struct NotificationSettingsViewModelTestSuite {
    private static func makeSUT(
        notificationSettingsUseCase: any NotificationSettingsUseCaseProtocol = MockNotificationSettingsUseCase()
    ) -> NotificationSettingsViewModel {
        NotificationSettingsViewModel(
            notificationSettingsUseCase: notificationSettingsUseCase
        )
    }
    
    @Suite("Mute notification timeout Tests")
    @MainActor struct MuteNotificationsTests {
        @Test(
            "Select mute notification time value preset",
            arguments: TimeValuePreset.muteNotificationOptions()
        )
        func muteNotificationPresetTapped(_ preset: TimeValuePreset) async {
            let notificationSettingsUseCase = MockNotificationSettingsUseCase()
            let sut = makeSUT(
                notificationSettingsUseCase: notificationSettingsUseCase
            )
            
            await sut.muteNotificationsPresetTapped(preset)
            
            #expect(notificationSettingsUseCase.setPushNotificationSettings_calledCount == 1)
        }
        
        @Test(
            "Disable/Enable chat notifications",
            arguments: [false, true]
        )
        func toggleChatNotifications(_ enabled: Bool) async {
            let notificationSettingsUseCase = MockNotificationSettingsUseCase()
            let sut = makeSUT(
                notificationSettingsUseCase: notificationSettingsUseCase
            )
            
            await sut.toggleChatNotifications(isCurrentlyEnabled: enabled)
            
            #expect(sut.isChatNotificationsEnabled == !enabled)
            #expect(notificationSettingsUseCase.setPushNotificationSettings_calledCount == 1)
        }
    }
}
