import MEGADomain
import MEGADomainMock
import Testing

@testable import Settings

@Suite("ChatSettingsViewModelTestSuite")
@MainActor struct ChatSettingsViewModelTestSuite {
    private static func makeSUT(
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        chatUseCase: any ChatUseCaseProtocol = MockChatUseCase(),
        chatPresenceUseCase: any ChatPresenceUseCaseProtocol = MockChatPresenceUseCase(),
        navigateToStatus: @escaping () -> Void = { },
        navigateToNotifications: @escaping () -> Void = { },
        navigateToMediaQuality: @escaping () -> Void = { }
    ) -> ChatSettingsViewModel {
        ChatSettingsViewModel(
            accountUseCase: accountUseCase,
            chatUseCase: chatUseCase,
            chatPresenceUseCase: chatPresenceUseCase,
            navigateToStatus: navigateToStatus,
            navigateToNotifications: navigateToNotifications,
            navigateToMediaQuality: navigateToMediaQuality
        )
    }
    
    @Suite("OnlineStatus Tests")
    @MainActor struct OnlineStatusTests {
        @Test("OnlineStatus Change Received but not for my user, should not change the status")
        func onlineStatusChangeReceived_notMyUser() async {
            let chatPresenceUseCase = MockChatPresenceUseCase()
            let chatUseCase = MockChatUseCase(myUserHandle: 100)
            chatPresenceUseCase.setOnlineStatus(.online)
            let sut = makeSUT(
                chatUseCase: chatUseCase,
                chatPresenceUseCase: chatPresenceUseCase
            )
            await sut.fetchData()
            let currentOnlineStatusString = sut.onlineStatusString
            
            chatPresenceUseCase.sendChatOnlineStatusUpdate((.invalid, .online, false))
            try? await Task.sleep(nanoseconds: 100_000_000)

            #expect(sut.onlineStatusString == currentOnlineStatusString)
        }
        
        @Test("OnlineStatus Change Received but is in progress, should not change the status")
        func onlineStatusChangeReceived_isInProgress() async {
            let chatPresenceUseCase = MockChatPresenceUseCase()
            let chatUseCase = MockChatUseCase(myUserHandle: 100)
            chatPresenceUseCase.setOnlineStatus(.online)
            let sut = makeSUT(
                chatUseCase: chatUseCase,
                chatPresenceUseCase: chatPresenceUseCase
            )
            await sut.fetchData()
            let currentOnlineStatusString = sut.onlineStatusString
            
            chatPresenceUseCase.sendChatOnlineStatusUpdate((100, .online, true))
            try? await Task.sleep(nanoseconds: 100_000_000)

            #expect(sut.onlineStatusString == currentOnlineStatusString)
        }
        
        @Test(
            "OnlineStatus Change Received not in progress and for my user, it should update the status string",
            arguments: ChatStatusEntity.options()
        )
        func onlineStatusChangeReceived_myUserNotInProgress(_ status: ChatStatusEntity) async {
            let chatUseCase = MockChatUseCase(myUserHandle: 100)
            let chatPresenceUseCase = MockChatPresenceUseCase()
            chatPresenceUseCase.setOnlineStatus(.invalid)
            let sut = makeSUT(
                chatUseCase: chatUseCase,
                chatPresenceUseCase: chatPresenceUseCase
            )
            await sut.fetchData()
            let currentOnlineStatusString = sut.onlineStatusString
            
            chatPresenceUseCase.sendChatOnlineStatusUpdate((100, status, false))
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            #expect(sut.onlineStatusString == status.localizedIdentifier)
            #expect(sut.onlineStatusString != currentOnlineStatusString)
        }
    }
    
    @Suite("RichLinkPreview Tests")
    @MainActor struct RichLinkPreviewTests {
        @Test("Toggle rich link previews", arguments: [true, false])
        func toggleEnableRichLinkPreviews(isEnabled: Bool) {
            let accountUseCase = MockAccountUseCase(richLinkPreviewEnabled: isEnabled)
            let sut = makeSUT(accountUseCase: accountUseCase)
            
            sut.toggleEnableRichLinkPreview(isCurrentlyEnabled: isEnabled)
            
            #expect(accountUseCase.enableRichLinkPreview_calledCount == 1)
            #expect(sut.isRichLinkPreviewEnabled == !isEnabled)
        }
    }
    
    @Suite("Navigation Tests")
    @MainActor struct NavigationTests {
        @Test("Navigate to status view")
        func onTapNavigateToStatusView() {
            var navigateToStatusCount = 0
            let sut = makeSUT(
                navigateToStatus: { navigateToStatusCount += 1 }
            )
            
            sut.statusViewTapped()
            
            #expect(navigateToStatusCount == 1)
        }
        
        @Test("Navigate to notifications view")
        func onTapNavigateToNotificationsView() {
            var navigateToNotificationSettingsCount = 0
            let sut = makeSUT(
                navigateToNotifications: { navigateToNotificationSettingsCount += 1 }
            )
            
            sut.notificationsViewTapped()
            
            #expect(navigateToNotificationSettingsCount == 1)
        }
        
        @Test("Navigate to media quality view")
        func onTapNavigateToMediaQualityView() {
            var navigateToMediaQualityCount = 0
            let sut = makeSUT(
                navigateToMediaQuality: { navigateToMediaQualityCount += 1 }
            )
            
            sut.mediaQualityViewTapped()
            
            #expect(navigateToMediaQualityCount == 1)
        }
    }
}
