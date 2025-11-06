import MEGADomain
import MEGADomainMock
import MEGAL10n
@testable import Settings
import Testing

@Suite("SetStatusViewModelTestSuite")
@MainActor struct SetStatusViewModelTestSuite {
    private static func makeSUT(
        chatUseCase: any ChatUseCaseProtocol = MockChatUseCase(),
        chatPresenceUseCase: any ChatPresenceUseCaseProtocol = MockChatPresenceUseCase()
    ) -> SetStatusViewModel {
        SetStatusViewModel(
            chatUseCase: chatUseCase,
            chatPresenceUseCase: chatPresenceUseCase
        )
    }
    
    private static func mockPresenceConfig(status: ChatStatusEntity = .invalid, autoAwayEnabled: Bool = false, autoAwayTimeout: Int64 = 0, persist: Bool = false, pending: Bool = false, lastGreenVisible: Bool = false) -> ChatPresenceConfigEntity {
        ChatPresenceConfigEntity(status: status, autoAwayEnabled: autoAwayEnabled, autoAwayTimeout: autoAwayTimeout, persist: persist, pending: pending, lastGreenVisible: lastGreenVisible)
    }
    
    @Suite("SetOnlineStatus Tests")
    @MainActor struct SetOnlineStatusTests {
        @Test(
            "OnlineStatus tapped, it should update the status",
            arguments: ChatStatusEntity.options()
        )
        func onlineStatusTapped(_ status: ChatStatusEntity) async {
            let chatPresenceUseCase = MockChatPresenceUseCase(
                chatPresenceConfig: mockPresenceConfig()
            )
            
            let sut = makeSUT(chatPresenceUseCase: chatPresenceUseCase)
            await sut.fetchData()
            
            sut.onlineStatusTapped(status)
            #expect(chatPresenceUseCase.setOnlineStatus_calledTimes == 1)
        }
        
        @Test(
            "OnlineStatus tapped is same than current status, it should update the status",
            arguments: ChatStatusEntity.options()
        )
        func currentOnlineStatusTapped(_ status: ChatStatusEntity) async {
            let chatPresenceUseCase = MockChatPresenceUseCase(
                chatPresenceConfig: mockPresenceConfig(status: status)
            )
            
            let sut = makeSUT(chatPresenceUseCase: chatPresenceUseCase)
            await sut.fetchData()
            
            sut.onlineStatusTapped(status)
            #expect(chatPresenceUseCase.setOnlineStatus_calledTimes == 0)
        }
    }
    
    @Suite("Presence config Tests")
    @MainActor struct PresenceConfigTests {
        @Test(
            "Presence config updates with online status and auto away enabled",
            arguments: [TimeValuePreset.fiveMinutes, TimeValuePreset.thirtyMinutes, TimeValuePreset.fortyFiveMinutes, TimeValuePreset.oneHour, TimeValuePreset.threeHours, TimeValuePreset.sixHours]
        )
        func configPresenceUpdatedWithAutoAwayEnabled(_ preset: TimeValuePreset) async {
            let chatPresenceUseCase = MockChatPresenceUseCase()
            chatPresenceUseCase.setOnlineStatus(.invalid)
            let sut = makeSUT(
                chatPresenceUseCase: chatPresenceUseCase
            )
            
            let presenceConfig = mockPresenceConfig(
                status: .online,
                autoAwayEnabled: true,
                autoAwayTimeout: Int64(preset.timeInterval)
            )
            chatPresenceUseCase.sendOnPresenceConfigUpdate(presenceConfig)
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            #expect(sut.isAutoAwayVisible == true)
            #expect(sut.currentAutoAwayPreset == preset)
            #expect(sut.autoAwayTimeString == Strings.Localizable.Settings.Chat.Status.SetStatus.StatusSettings.AutoAway.subtitle(presenceConfig.autoAwayFormatString))
        }
        
        @Test("Presence config updates with online status and auto away disabled")
        func configPresenceUpdatedWithAutoAwayDisable() async {
            let chatPresenceUseCase = MockChatPresenceUseCase()
            chatPresenceUseCase.setOnlineStatus(.invalid)
            let sut = makeSUT(
                chatPresenceUseCase: chatPresenceUseCase
            )
            
            let presenceConfig = mockPresenceConfig(
                status: .online,
                autoAwayEnabled: false,
                autoAwayTimeout: 0
            )
            chatPresenceUseCase.sendOnPresenceConfigUpdate(presenceConfig)
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            #expect(sut.isAutoAwayVisible == true)
            #expect(sut.currentAutoAwayPreset == .never)
            #expect(sut.autoAwayTimeString == Strings.Localizable.never)
        }
        
        @Test(
            "Presence config updates with not online status and auto away disabled",
            arguments: [ChatStatusEntity.away, ChatStatusEntity.busy, ChatStatusEntity.offline]
        )
        func configPresenceUpdatedWithAutoAwayEnabled(_ status: ChatStatusEntity) async {
            let chatPresenceUseCase = MockChatPresenceUseCase()
            chatPresenceUseCase.setOnlineStatus(.invalid)
            let sut = makeSUT(
                chatPresenceUseCase: chatPresenceUseCase
            )
            
            let presenceConfig = mockPresenceConfig(
                status: status,
                autoAwayEnabled: false,
                autoAwayTimeout: 0
            )
            chatPresenceUseCase.sendOnPresenceConfigUpdate(presenceConfig)
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            #expect(sut.isAutoAwayVisible == false)
            #expect(sut.currentAutoAwayPreset == .never)
            #expect(sut.autoAwayTimeString == Strings.Localizable.never)
        }
    }
    
    @Suite("AutoAway Tests")
    @MainActor struct AutoAwayTests {
        @Test(
            "Select auto away time value preset, should call use case",
            arguments: TimeValuePreset.autoAwayOptions()
        )
        func autoAwayPresetTapped(_ preset: TimeValuePreset) async {
            let chatPresenceUseCase = MockChatPresenceUseCase()
            chatPresenceUseCase.setOnlineStatus(.invalid)
            let sut = makeSUT(
                chatPresenceUseCase: chatPresenceUseCase
            )
            
            sut.autoAwayPresetTapped(preset)
            
            #expect(chatPresenceUseCase.setAutoAwayPresence_calledTimes == 1)
        }
    }
}
