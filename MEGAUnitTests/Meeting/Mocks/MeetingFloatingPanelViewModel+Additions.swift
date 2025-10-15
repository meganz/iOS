@testable import MEGA
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGASwift

// mock for MeetingFloatingPanelHeaderConfigFactoryProtocol
struct MockMeetingFloatingPanelHeaderConfigFactory: MeetingFloatingPanelHeaderConfigFactoryProtocol {
    func headerConfig(
        tab: ParticipantsListTab,
        freeTierInCallParticipantLimitReached: Bool,
        totalInCallAndWaitingRoomAboveFreeTierLimit: Bool,
        participantsCount: Int,
        isMyselfAModerator: Bool,
        hasDismissedBanner: Bool,
        shouldHideCallAllIcon: Bool,
        shouldDisableMuteAllButton: Bool,
        dismissFreeUserLimitBanner: @escaping ActionHandler,
        actionButtonTappedHandler: @escaping ActionHandler
    ) -> MeetingParticipantTableViewHeader.ViewConfig {
        .init(
            title: "title",
            actionButtonNormalTitle: "Normal",
            actionButtonDisabledTitle: "Disabled",
            actionButtonHidden: false, 
            actionButtonEnabled: true,
            callAllButtonHidden: false,
            actionButtonTappedHandler: actionButtonTappedHandler,
            infoViewModel: nil
        )
    }
}

@MainActor
extension MeetingFloatingPanelViewModel {
    static func make(
        router: MockMeetingFloatingPanelRouter = MockMeetingFloatingPanelRouter(),
        containerViewModel: MeetingContainerViewModel? = nil,
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        callUseCase: MockCallUseCase = MockCallUseCase(),
        callUpdateUseCase: MockCallUpdateUseCase = MockCallUpdateUseCase(),
        sessionUpdateUseCase: MockSessionUpdateUseCase = MockSessionUpdateUseCase(),
        chatRoomUpdateUseCase: MockChatRoomUpdateUseCase = MockChatRoomUpdateUseCase(),
        accountUseCase: MockAccountUseCase = MockAccountUseCase(),
        chatRoomUseCase: MockChatRoomUseCase = MockChatRoomUseCase(),
        chatUseCase: MockChatUseCase = MockChatUseCase(),
        selectWaitingRoomList: Bool = false,
        headerConfigFactory: MockMeetingFloatingPanelHeaderConfigFactory
    ) -> MeetingFloatingPanelViewModel {
        .init(
            router: router,
            containerViewModel: containerViewModel ?? MeetingContainerViewModel(),
            chatRoom: chatRoom,
            callUseCase: callUseCase, 
            callUpdateUseCase: callUpdateUseCase,
            sessionUpdateUseCase: sessionUpdateUseCase, 
            chatRoomUpdateUseCase: chatRoomUpdateUseCase,
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatUseCase: chatUseCase,
            selectWaitingRoomList: selectWaitingRoomList,
            headerConfigFactory: headerConfigFactory,
            featureFlags: MockFeatureFlagProvider(list: .init()), 
            notificationCenter: NotificationCenter.default,
            tracker: MockTracker()
        )
    }
}
