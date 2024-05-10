@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentationMock

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
        presentUpgradeFlow: @escaping ActionHandler,
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

extension MeetingFloatingPanelViewModel {
    static func make(
        router: some MeetingFloatingPanelRouting = MockMeetingFloatingPanelRouter(),
        containerViewModel: MeetingContainerViewModel = MeetingContainerViewModel(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        isSpeakerEnabled: Bool = false,
        callKitManager: some CallKitManagerProtocol = MockCallKitManager(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(
            photoAuthorization: .denied,
            audioAuthorized: false,
            videoAuthorized: false
        ),
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
        localVideoUseCase: some CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        selectWaitingRoomList: Bool = false,
        headerConfigFactory: some MeetingFloatingPanelHeaderConfigFactoryProtocol,
        callManager: some CallManagerProtocol = MockCallManager()
    ) -> MeetingFloatingPanelViewModel {
        .init(
            router: router,
            containerViewModel: containerViewModel,
            chatRoom: chatRoom,
            isSpeakerEnabled: isSpeakerEnabled,
            callKitManager: callKitManager,
            callUseCase: callUseCase,
            audioSessionUseCase: audioSessionUseCase,
            permissionHandler: permissionHandler,
            captureDeviceUseCase: captureDeviceUseCase,
            localVideoUseCase: localVideoUseCase,
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            megaHandleUseCase: megaHandleUseCase,
            chatUseCase: chatUseCase,
            selectWaitingRoomList: selectWaitingRoomList,
            headerConfigFactory: headerConfigFactory,
            callManager: callManager,
            featureFlags: MockFeatureFlagProvider(list: .init()),
            presentUpgradeFlow: {_ in }
        )
    }
}
