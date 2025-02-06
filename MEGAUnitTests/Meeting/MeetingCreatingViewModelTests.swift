@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class MeetingCreatingViewModelTests: XCTestCase {
    @MainActor func testAction_onViewReady_createMeeting() {
        let router = MockMeetingCreateRouter()
        let sut = makeSUT(
            router: router,
            type: .start
        )
        
        test(viewModel: sut,
             action: .onViewReady,
             expectedCommands: [
                .updatedAudioPortSelection(audioPort: .builtInSpeaker, bluetoothAudioRouteAvailable: false),
                .configView(title: "Test Name’s meeting", type: .start, isMicrophoneEnabled: false)
             ])
    }
    
    @MainActor func testAction_onViewReady_joinMeeting() {
        let router = MockMeetingCreateRouter()
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let sut = makeSUT(
            router: router,
            type: .join,
            meetingUseCase: MockMeetingCreatingUseCase(
                checkChatLinkCompletion: .success(chatRoom)
            ),
            link: "Test link"
        )
        
        test(viewModel: sut,
             action: .onViewReady,
             expectedCommands: [
                .updatedAudioPortSelection(audioPort: .builtInSpeaker, bluetoothAudioRouteAvailable: false),
                .loadingStartMeeting,
                .loadingEndMeeting,
                .configView(title: "Unit tests", type: .join, isMicrophoneEnabled: false)
             ])
    }
    
    @MainActor func testAction_updateSpeakerButton() {
        let router = MockMeetingCreateRouter()
        let sut = makeSUT(
            router: router,
            type: .join
        )
        
        test(viewModel: sut,
             action: .didTapSpeakerButton,
             expectedCommands: [
                .updatedAudioPortSelection(audioPort: .builtInReceiver, bluetoothAudioRouteAvailable: false)
             ])
    }
    
    @MainActor
    func testAction_didTapCloseButton() {
        let router = MockMeetingCreateRouter()
        let sut = makeSUT(
            router: router,
            type: .join
        )
        
        sut.dispatch(.didTapCloseButton)
        XCTAssert(router.dismiss_calledTimes == 1)
    }
    
    @MainActor
    func testAction_didTapStartMeetingButton_userJoiningToNewChat_userShouldJoinChatDismissViewAndJoinActiveCall() {
        let router = MockMeetingCreateRouter()
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callController = MockCallController()
        let sut = makeSUT(
            router: router,
            type: .join,
            meetingUseCase: MockMeetingCreatingUseCase(
                joinCallCompletion: .success(chatRoom),
                checkChatLinkCompletion: .success(chatRoom)
            ),
            callController: callController,
            link: "https://mega-chat-link.com"
        )
        
        test(viewModel: sut,
             action: .onViewReady,
             expectedCommands: [
                .updatedAudioPortSelection(audioPort: .builtInSpeaker, bluetoothAudioRouteAvailable: false),
                .loadingStartMeeting,
                .loadingEndMeeting,
                .configView(title: "Unit tests", type: .join, isMicrophoneEnabled: false)
             ])
        
        test(viewModel: sut,
             action: .didTapStartMeetingButton,
             expectedCommands: [
                .loadingStartMeeting
             ])
        
        evaluate {
            router.dismiss_calledTimes == 1 &&
            callController.startCall_CalledTimes == 1
        }
    }
    
    @MainActor
    func testAction_didTapStartMeetingButton_userJoiningChatAlreadyParticipating_viewShouldDismissAndJoinActiveCall() {
        let router = MockMeetingCreateRouter()
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callController = MockCallController()
        let sut = makeSUT(
            router: router,
            type: .join,
            meetingUseCase: MockMeetingCreatingUseCase(
                checkChatLinkCompletion: .success(chatRoom)
            ),
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: chatRoom),
            callController: callController,
            link: "https://mega-chat-link.com"
        )
        
        test(viewModel: sut,
             action: .onViewReady,
             expectedCommands: [
                .updatedAudioPortSelection(audioPort: .builtInSpeaker, bluetoothAudioRouteAvailable: false),
                .loadingStartMeeting,
                .loadingEndMeeting,
                .configView(title: "Unit tests", type: .join, isMicrophoneEnabled: false)
             ])
        
        test(viewModel: sut,
             action: .didTapStartMeetingButton,
             expectedCommands: [
                .loadingStartMeeting
             ])
        
        evaluate {
            router.dismiss_calledTimes == 1 &&
            callController.startCall_CalledTimes == 1
        }
    }
    
    @MainActor func testDidTapStartMeetingButton_forGuestJoin_shouldTrackEvent() async {
        let chatRoom = ChatRoomEntity(chatId: 1, title: "Test Meeting")
        let tracker = MockTracker()
        let sut = makeSUT(
            type: .guestJoin,
            meetingUseCase: MockMeetingCreatingUseCase(
                createEphemeralAccountCompletion: .success(()),
                joinCallCompletion: .success(chatRoom),
                checkChatLinkCompletion: .success(chatRoom)
            ),
            tracker: tracker,
            link: "Test link"
        )
        
        await test(viewModel: sut,
                   actions: [.onViewReady],
                   expectedCommands: [
                    .updatedAudioPortSelection(audioPort: .builtInSpeaker, bluetoothAudioRouteAvailable: false),
                    .loadingStartMeeting,
                    .loadingEndMeeting,
                    .configView(title: "Test Meeting", type: .guestJoin, isMicrophoneEnabled: false)
                   ],
                   expectationValidation: ==
        )
        
        await test(viewModel: sut,
                   actions: [.didTapStartMeetingButton],
                   expectedCommands: [.loadingStartMeeting],
                   expectationValidation: ==
        )
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingJoinGuestButtonEvent()
            ]
        )
    }
    
    // MARK: - Private
    
    @MainActor private func makeSUT(
        router: some MeetingCreatingViewRouting = MockMeetingCreateRouter(),
        type: MeetingConfigurationType = .guestJoin,
        meetingUseCase: some MeetingCreatingUseCaseProtocol = MockMeetingCreatingUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        localVideoUseCase: some CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
        permissionHandler: some DevicePermissionsHandling =  MockDevicePermissionHandler(
            photoAuthorization: .authorized,
            audioAuthorized: false,
            videoAuthorized: false
        ),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        callController: some CallControllerProtocol = MockCallController(),
        tracker: some AnalyticsTracking = DIContainer.tracker,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        link: String? = nil,
        userHandle: UInt64 = 0
    ) -> MeetingCreatingViewModel {
        MeetingCreatingViewModel(
            router: router,
            type: type,
            meetingUseCase: meetingUseCase,
            audioSessionUseCase: audioSessionUseCase,
            localVideoUseCase: localVideoUseCase,
            captureDeviceUseCase: captureDeviceUseCase,
            permissionHandler: permissionHandler,
            userImageUseCase: userImageUseCase,
            accountUseCase: accountUseCase,
            megaHandleUseCase: megaHandleUseCase,
            callUseCase: callUseCase,
            callController: callController,
            chatRoomUseCase: chatRoomUseCase,
            tracker: tracker,
            featureFlagProvider: featureFlagProvider,
            link: link,
            userHandle: userHandle
        )
    }
}

final class MockMeetingCreateRouter: MeetingCreatingViewRouting {
    var dismiss_calledTimes = 0
    var goToMeetingRoom_calledTimes = 0
    var openChatRoom_calledTimes = 0
    var showVideoPermissionError_calledTimes = 0
    var showAudioPermissionError_calledTimes = 0
    
    nonisolated init() {}
    
    func dismiss(completion: (() -> Void)?) {
        dismiss_calledTimes += 1
        completion?()
    }
    
    func goToMeetingRoom(chatRoom: ChatRoomEntity, call: CallEntity, isSpeakerEnabled: Bool) {
        goToMeetingRoom_calledTimes += 1
    }
    
    func openChatRoom(withChatId chatId: UInt64) {
        openChatRoom_calledTimes += 1
    }
    
    func showVideoPermissionError() {
        showVideoPermissionError_calledTimes += 1
    }
    
    func showAudioPermissionError() {
        showAudioPermissionError_calledTimes += 1
    }
}
