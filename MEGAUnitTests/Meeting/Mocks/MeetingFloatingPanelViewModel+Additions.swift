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
        router: some MeetingFloatingPanelRouting = MockMeetingFloatingPanelRouter(),
        containerViewModel: MeetingContainerViewModel? = nil,
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        callUpdateUseCase: some CallUpdateUseCaseProtocol = MockCallUpdateUseCase(),
        sessionUpdateUseCase: some SessionUpdateUseCaseProtocol = MockSessionUpdateUseCase(),
        chatRoomUpdateUseCase: some ChatRoomUpdateUseCaseProtocol = MockChatRoomUpdateUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        selectWaitingRoomList: Bool = false,
        headerConfigFactory: some MeetingFloatingPanelHeaderConfigFactoryProtocol
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
