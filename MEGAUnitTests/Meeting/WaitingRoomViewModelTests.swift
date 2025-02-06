import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentationMock
import MEGATest
import XCTest

final class WaitingRoomViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    @MainActor
    func testMeetingTitle_onLoadWaitingRoom_shouldMatch() {
        let meetingTitle = "Test Meeting"
        let scheduledMeeting = ScheduledMeetingEntity(title: meetingTitle)
        let sut = WaitingRoomViewModel(scheduledMeeting: scheduledMeeting)
        
        XCTAssertEqual(sut.meetingTitle, meetingTitle)
    }
    
    @MainActor
    func testMeetingDate_givenMeetingStartAndEndDate_shouldMatch() throws {
        let startDate = try XCTUnwrap(sampleDate(from: "21/09/2023 10:30"))
        let endDate = try XCTUnwrap(sampleDate(from: "21/09/2023 10:45"))
        let scheduledMeeting = ScheduledMeetingEntity(startDate: startDate, endDate: endDate)
        let sut = WaitingRoomViewModel(scheduledMeeting: scheduledMeeting)
        
        XCTAssertEqual(sut.createMeetingDate(locale: Locale(identifier: "en_GB")), "Thu, 21 Sep ·10:30-10:45")
    }
    
    @MainActor
    func testViewState_onLoadWaitingRoomAndIsGuest_shouldBeGuestJoinState() {
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
        XCTAssertEqual(sut.viewState, .guestUserSetup)
    }
    
    @MainActor
    func testViewState_onLoadWaitingRoomAndIsNotGuestAndMeetingNotStart_shouldBeWaitForHostToStartState() {
        let callUseCase = MockCallUseCase(call: nil)
        let sut = WaitingRoomViewModel(callUseCase: callUseCase)
        XCTAssertEqual(sut.viewState, .waitForHostToStart)
    }
    
    @MainActor
    func testViewState_onLoadWaitingRoomAndIsNotGuestAndMeetingDidStart_shouldBeWaitForHostToStartState() {
        let sut = WaitingRoomViewModel()
        XCTAssertEqual(sut.viewState, .waitForHostToLetIn)
    }
    
    @MainActor
    func testViewState_onMeetingNotStartTransitsToMeetingDidStart_shouldChangeFromWaitForHostToStartToWaitForHostToLetIn() {
        let scheduledMeeting = ScheduledMeetingEntity(chatId: 100)
        let callEntity = CallEntity(status: .connecting, chatId: 100)
        let callUseCase = MockCallUseCase(call: nil)
        let callUpdateUseCase = MockCallUpdateUseCase()
        let sut = WaitingRoomViewModel(
            scheduledMeeting: scheduledMeeting,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity()),
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase
        )
        
        XCTAssertEqual(sut.viewState, .waitForHostToStart)
        
        callUseCase.call = callEntity
        callUpdateUseCase.sendCallUpdate(callEntity)
        
        evaluate {
            sut.viewState == .waitForHostToLetIn
        }
    }
    
    @MainActor
    func testViewState_onMeetingDidStartTransitsToMeetingNotStart_shouldChangeFromWaitForHostToLetInToWaitForHostToStart() {
        let scheduledMeeting = ScheduledMeetingEntity(chatId: 100)
        let chatUseCase = MockChatUseCase(isActiveWaitingRoom: true)
        let callUseCase = MockCallUseCase()
        let callUpdateUseCase = MockCallUpdateUseCase()

        let sut = WaitingRoomViewModel(
            scheduledMeeting: scheduledMeeting,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase
        )
        
        XCTAssertEqual(sut.viewState, .waitForHostToLetIn)
        
        callUseCase.call = nil
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .terminatingUserParticipation, chatId: 100))
        
        evaluate {
            sut.viewState == .waitForHostToStart
        }
    }
    
    @MainActor
    func testSpeakerButton_onTapSpeakerButton_shouldDisableSpeakerButton() {
        let audioSessionUseCase = MockAudioSessionUseCase()
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        sut.enableLoudSpeaker(enabled: false)
        
        XCTAssertEqual(audioSessionUseCase.disableLoudSpeaker_calledTimes, 1)
    }
    
    @MainActor
    func testCalculateVideoSize_portraitMode_shouldMatch() {
        let screenHeight = 424.0
        let screenWidth = 236.0
        let sut = WaitingRoomViewModel()
        sut.screenSize = CGSize(width: screenWidth, height: screenHeight)
        
        let videoSize = sut.calculateVideoSize()
        
        XCTAssertEqual(videoSize, calculateVideoSize(by: screenHeight, isLandscape: false))
    }
    
    @MainActor
    func testCalculateVideoSize_landscapeMode_shouldMatch() {
        let screenHeight = 236.0
        let screenWidth = 424.0
        let sut = WaitingRoomViewModel()
        sut.screenSize = CGSize(width: screenWidth, height: screenHeight)
        
        let videoSize = sut.calculateVideoSize()
        
        XCTAssertEqual(videoSize, calculateVideoSize(by: screenHeight, isLandscape: true))
    }
    
    @MainActor
    func testCalculateBottomPanelHeight_portraitModeAndGuestJoin_shouldMatch() {
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
        
        XCTAssertEqual(sut.calculateBottomPanelHeight(), 142.0)
    }
    
    @MainActor
    func testCalculateBottomPanelHeight_portraitModeAndWaitForHostToLetIn_shouldMatch() {
        let sut = WaitingRoomViewModel()
        
        XCTAssertEqual(sut.calculateBottomPanelHeight(), 100.0)
    }
    
    @MainActor
    func testCalculateBottomPanelHeight_landscapeModeAndGuestJoin_shouldMatch() {
        let screenHeight = 236.0
        let screenWidth = 424.0
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
        sut.screenSize = CGSize(width: screenWidth, height: screenHeight)
        
        XCTAssertEqual(sut.calculateBottomPanelHeight(), 142.0)
    }
    
    @MainActor
    func testCalculateBottomPanelHeight_landscapeModeAndWaitForHostToLetIn_shouldMatch() {
        let screenHeight = 236.0
        let screenWidth = 424.0
        let sut = WaitingRoomViewModel()
        sut.screenSize = CGSize(width: screenWidth, height: screenHeight)
        
        XCTAssertEqual(sut.calculateBottomPanelHeight(), 8.0)
    }
    
    @MainActor
    func testShowWaitingRoomMessage_whenGuestLogin_shouldNotShow() {
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
        
        XCTAssertFalse(sut.showWaitingRoomMessage)
    }
    
    @MainActor
    func testShowWaitingRoomMessage_whenWaitForHostToStart_shouldShow() {
        let chatUseCase = MockChatUseCase(isActiveWaitingRoom: false)
        let sut = WaitingRoomViewModel(chatUseCase: chatUseCase)
        
        XCTAssertTrue(sut.showWaitingRoomMessage)
    }
    
    @MainActor
    func testShowWaitingRoomMessage_whenWaitForHostToLetIn_shouldShow() {
        let chatUseCase = MockChatUseCase(isActiveWaitingRoom: true)
        let sut = WaitingRoomViewModel(chatUseCase: chatUseCase)
        
        XCTAssertTrue(sut.showWaitingRoomMessage)
    }
    
    @MainActor
    func testWaitingRoomMessage_whenWaitForHostToStart_shouldMatch() {
        let callUseCase = MockCallUseCase(call: nil)
        let sut = WaitingRoomViewModel(callUseCase: callUseCase)
        
        XCTAssertEqual(sut.waitingRoomMessage, Strings.Localizable.Meetings.WaitingRoom.Message.waitForHostToStartTheMeeting)
    }
    
    @MainActor
    func testWaitingRoomMessage_whenWaitForHostToLetIn_shouldMatch() {
        let sut = WaitingRoomViewModel()
        
        XCTAssertEqual(sut.waitingRoomMessage, Strings.Localizable.Meetings.WaitingRoom.Message.waitForHostToLetYouIn)
    }
    
    @MainActor
    func testTapJoinAction_onCreateEphemeralAccountSuccessAndJoinChatSuccessAndMeetingDidStart_shoudBecomeWaitForHostToLetIn() {
        let callUseCase = MockCallUseCase(call: CallEntity(), answerCallCompletion: .success(CallEntity()))
        let meetingUseCase = MockMeetingCreatingUseCase(createEphemeralAccountCompletion: .success, joinCallCompletion: .success(ChatRoomEntity()))
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let callController = MockCallController()
        let sut = WaitingRoomViewModel(chatRoomUseCase: chatRoomUseCase,
                                       callUseCase: callUseCase,
                                       callController: callController,
                                       meetingUseCase: meetingUseCase,
                                       accountUseCase: accountUseCase,
                                       chatLink: "Test chatLink")
        
        XCTAssertEqual(sut.viewState, .guestUserSetup)
        
        sut.tapJoinAction(firstName: "First", lastName: "Last")
        
        evaluate {
            sut.viewState == .waitForHostToLetIn &&
            callController.startCall_CalledTimes == 1
        }
    }
    
    @MainActor
    func testTapJoinAction_onCreateEphemeralAccountSuccessAndJoinChatSuccessAndMeetingNotStart_shoudBecomeWaitForHostToStart() {
        let callUseCase = MockCallUseCase(call: nil, answerCallCompletion: .success(CallEntity()))
        let meetingUseCase = MockMeetingCreatingUseCase(createEphemeralAccountCompletion: .success, joinCallCompletion: .success(ChatRoomEntity()))
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(callUseCase: callUseCase,
                                       meetingUseCase: meetingUseCase,
                                       accountUseCase: accountUseCase,
                                       chatLink: "Test chatLink")
        
        XCTAssertEqual(sut.viewState, .guestUserSetup)
        
        sut.tapJoinAction(firstName: "First", lastName: "Last")
        
        evaluate {
            sut.viewState == .waitForHostToStart
        }
    }
    
    @MainActor
    func testTapJoinAction_onCreateEphemeralAccountSuccessAndJoinChatFail_shoudDismiss() {
        let router = MockWaitingRoomViewRouter()
        let callUseCase = MockCallUseCase(call: nil, answerCallCompletion: .success(CallEntity()))
        let meetingUseCase = MockMeetingCreatingUseCase(createEphemeralAccountCompletion: .success)
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(router: router,
                                       callUseCase: callUseCase,
                                       meetingUseCase: meetingUseCase,
                                       accountUseCase: accountUseCase,
                                       chatLink: "Test chatLink")
        
        XCTAssertEqual(sut.viewState, .guestUserSetup)
        
        sut.tapJoinAction(firstName: "First", lastName: "Last")
        
        evaluate {
            router.dismiss_calledTimes == 1
        }
    }
    
    @MainActor
    func testUserAvatar_onLoadWaitingRoomAndIsNotGuest_shouldShowAvatar() {
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity())
        let userImageUseCase = MockUserImageUseCase(fetchAvatarResult: .success("image"))
        let sut = WaitingRoomViewModel(megaHandleUseCase: megaHandleUseCase, userImageUseCase: userImageUseCase)
        
        evaluate {
            sut.userAvatar != nil
        }
    }
    
    @MainActor
    func testUserAvatar_onLoadWaitingRoomAndIsGuest_shouldNotShowAvatar() {
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity())
        let userImageUseCase = MockUserImageUseCase()
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase,
                                       megaHandleUseCase: megaHandleUseCase,
                                       userImageUseCase: userImageUseCase)
        
        evaluate {
            sut.userAvatar == nil
        }
    }
    
    @MainActor
    func testUserAvatar_onLoadWaitingRoomAndIsGuestAndJoinsTheChat_shouldShowAvatar() {
        let callUseCase = MockCallUseCase(call: nil, answerCallCompletion: .success(CallEntity()))
        let meetingUseCase = MockMeetingCreatingUseCase(createEphemeralAccountCompletion: .success, joinCallCompletion: .success(ChatRoomEntity()))
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity())
        let userImageUseCase = MockUserImageUseCase(fetchAvatarResult: .success("image"))
        let sut = WaitingRoomViewModel(callUseCase: callUseCase,
                                       meetingUseCase: meetingUseCase,
                                       accountUseCase: accountUseCase,
                                       megaHandleUseCase: megaHandleUseCase,
                                       userImageUseCase: userImageUseCase,
                                       chatLink: "Test chatLink")
        
        XCTAssertEqual(sut.viewState, .guestUserSetup)
        
        sut.tapJoinAction(firstName: "First", lastName: "Last")
        
        evaluate {
            sut.userAvatar != nil
        }
    }
    
    @MainActor
    func testCheckChatLink_whenUserPrivilegeIsRemovedAndJoinChatCallSuccess_shoudBecomeWaitForHostToStart() {
        let callUseCase = MockCallUseCase(call: nil, answerCallCompletion: .success(CallEntity()))
        let meetingUseCase = MockMeetingCreatingUseCase(joinCallCompletion: .success(ChatRoomEntity()), checkChatLinkCompletion: .success(ChatRoomEntity(ownPrivilege: .removed)))
        let sut = WaitingRoomViewModel(callUseCase: callUseCase,
                                       meetingUseCase: meetingUseCase,
                                       chatLink: "Test chatLink")
        
        evaluate {
            sut.viewState == .waitForHostToStart
        }
    }
    
    @MainActor
    func testCheckChatLink_whenUserPrivilegeIsReadOnlyAndJoinChatCallSuccess_shoudBecomeWaitForHostToStart() {
        let callUseCase = MockCallUseCase(call: nil, answerCallCompletion: .success(CallEntity()))
        let meetingUseCase = MockMeetingCreatingUseCase(joinCallCompletion: .success(ChatRoomEntity()), checkChatLinkCompletion: .success(ChatRoomEntity(ownPrivilege: .readOnly)))
        let sut = WaitingRoomViewModel(callUseCase: callUseCase,
                                       meetingUseCase: meetingUseCase,
                                       chatLink: "Test chatLink")
        
        evaluate {
            sut.viewState == .waitForHostToStart
        }
    }
    
    // MARK: - Router related tests
    
    @MainActor
    func testLeaveButton_didTapLeaveButton_shouldPresentLeaveAlert() {
        let router = MockWaitingRoomViewRouter()
        let sut = WaitingRoomViewModel(router: router)
        
        sut.leaveButtonTapped()
        
        XCTAssertEqual(router.showLeaveAlert_calledTimes, 1)
    }
    
    @MainActor
    func testMeetingInfoButton_didTapMeetingInfoButton_shouldPresentMeetingInfo() {
        let router = MockWaitingRoomViewRouter()
        let sut = WaitingRoomViewModel(router: router)
        
        sut.infoButtonTapped()
        
        XCTAssertEqual(router.showMeetingInfo_calledTimes, 1)
    }
    
    @MainActor
    func testShowHostDenyAlert_onHostDeny_shouldShowDenyAlert() {
        let scheduledMeeting = ScheduledMeetingEntity(chatId: 100)
        let router = MockWaitingRoomViewRouter()
        let callEntity = CallEntity(status: .waitingRoom, chatId: 100, termCodeType: .kicked, waitingRoomStatus: .notAllowed)
        let callUpdateUseCase = MockCallUpdateUseCase()

        let sut = WaitingRoomViewModel(
            scheduledMeeting: scheduledMeeting,
            router: router,
            callUpdateUseCase: callUpdateUseCase
        )

        XCTAssertEqual(sut.viewState, .waitForHostToLetIn)

        callUpdateUseCase.sendCallUpdate(callEntity)
        
        evaluate {
            router.showHostDenyAlert_calledTimes == 1
        }
    }
    
    @MainActor
    func testShowHostDidNotRespondAlert_onTimeout_shouldHostDidNotRespondAlert() {
        let scheduledMeeting = ScheduledMeetingEntity(chatId: 100)
        let router = MockWaitingRoomViewRouter()
        let callEntity = CallEntity(status: .waitingRoom, chatId: 100, termCodeType: .waitingRoomTimeout, waitingRoomStatus: .notAllowed)
        let callUpdateUseCase = MockCallUpdateUseCase()
        let sut = WaitingRoomViewModel(
            scheduledMeeting: scheduledMeeting,
            router: router,
            callUpdateUseCase: callUpdateUseCase
        )

        XCTAssertEqual(sut.viewState, .waitForHostToLetIn)
        
        callUpdateUseCase.sendCallUpdate(callEntity)

        evaluate {
            router.showHostDidNotRespondAlert_calledTimes == 1
        }
    }
    
    @MainActor
    func testGoToCallUI_onHostAllowToJoinAndChangeTypeIsWaitingRoomAllow_shouldOpenCallUI() {
        let scheduledMeeting = ScheduledMeetingEntity(chatId: 100)
        let router = MockWaitingRoomViewRouter()
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let callEntity = CallEntity(chatId: 100, changeType: .waitingRoomAllow)
        let callUpdateUseCase = MockCallUpdateUseCase()
        let sut = WaitingRoomViewModel(
            scheduledMeeting: scheduledMeeting,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            callUpdateUseCase: callUpdateUseCase
        )
        
        XCTAssertEqual(sut.viewState, .waitForHostToLetIn)
        
        callUpdateUseCase.sendCallUpdate(callEntity)

        evaluate {
            router.openCallUI_calledTimes == 1
        }
    }
    
    @MainActor
    func testGoToCallUI_onHostAllowToJoinAndCallStatusIsInProgress_shouldOpenCallUI() {
        let scheduledMeeting = ScheduledMeetingEntity(chatId: 100)
        let router = MockWaitingRoomViewRouter()
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let callEntity = CallEntity(status: .inProgress, chatId: 100, changeType: .status)
        let callUpdateUseCase = MockCallUpdateUseCase()
        let sut = WaitingRoomViewModel(
            scheduledMeeting: scheduledMeeting,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            callUpdateUseCase: callUpdateUseCase
        )
        
        XCTAssertEqual(sut.viewState, .waitForHostToLetIn)
        
        callUpdateUseCase.sendCallUpdate(callEntity)

        evaluate {
            router.openCallUI_calledTimes == 1
        }
    }
    
    @MainActor
    func testUpdateSpeakerInfo_forCurrentPortBuiltInReceiver_shouldNotEnabledSpeaker() {
        let onAudioSessionRouteChangeSubject = PassthroughSubject<AudioSessionRouteChangedReason, Never>()
        let audioSessionUseCase = MockAudioSessionUseCase(currentSelectedAudioPort: .builtInReceiver, onAudioSessionRouteChangeSubject: onAudioSessionRouteChangeSubject)
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        onAudioSessionRouteChangeSubject.send(.categoryChange)
        
        evaluate {
            sut.isSpeakerEnabled == false
        }
    }
    
    @MainActor
    func testUpdateSpeakerInfo_forCurrentPortBuiltInSpeaker_shouldEnabledSpeaker() {
        let onAudioSessionRouteChangeSubject = PassthroughSubject<AudioSessionRouteChangedReason, Never>()
        let audioSessionUseCase = MockAudioSessionUseCase(currentSelectedAudioPort: .builtInSpeaker, onAudioSessionRouteChangeSubject: onAudioSessionRouteChangeSubject)
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        onAudioSessionRouteChangeSubject.send(.categoryChange)
        
        evaluate {
            sut.isSpeakerEnabled == true
        }
    }
    
    @MainActor
    func testUpdateSpeakerInfo_forCurrentPortOtherAndBluetoothAudioRouteAvailable_shouldEnabledSpeaker() {
        let onAudioSessionRouteChangeSubject = PassthroughSubject<AudioSessionRouteChangedReason, Never>()
        let audioSessionUseCase = MockAudioSessionUseCase(
            isBluetoothAudioRouteAvailable: true, 
            currentSelectedAudioPort: .other,
            onAudioSessionRouteChangeSubject: onAudioSessionRouteChangeSubject
        )
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        onAudioSessionRouteChangeSubject.send(.categoryChange)
        
        evaluate {
            sut.isSpeakerEnabled == true
        }
    }
    
    @MainActor
    func testUpdateSpeakerInfo_forCurrentPortOtherAndBluetoothAudioRouteNotAvailable_shouldNotEnabledSpeaker() {
        let onAudioSessionRouteChangeSubject = PassthroughSubject<AudioSessionRouteChangedReason, Never>()
        let audioSessionUseCase = MockAudioSessionUseCase(
            isBluetoothAudioRouteAvailable: false,
            currentSelectedAudioPort: .other,
            onAudioSessionRouteChangeSubject: onAudioSessionRouteChangeSubject
        )
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        onAudioSessionRouteChangeSubject.send(.categoryChange)
        
        evaluate {
            sut.isSpeakerEnabled == false
        }
    }
    
    @MainActor
    func testSpeakerOnIcon_forSelectedPortHeadphones_shouldBeSpeakerOnIcon() {
        let onAudioSessionRouteChangeSubject = PassthroughSubject<AudioSessionRouteChangedReason, Never>()
        let audioSessionUseCase = MockAudioSessionUseCase(
            isBluetoothAudioRouteAvailable: false,
            currentSelectedAudioPort: .headphones,
            onAudioSessionRouteChangeSubject: onAudioSessionRouteChangeSubject
        )
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        onAudioSessionRouteChangeSubject.send(.categoryChange)
        
        evaluate {
            sut.speakerOnIcon == .callControlSpeakerEnabled
        }
    }
    
    @MainActor
    func testSpeakerOnIcon_forSelectedPortBuiltInSpeaker_shouldBeSpeakerOnIcon() {
        let onAudioSessionRouteChangeSubject = PassthroughSubject<AudioSessionRouteChangedReason, Never>()
        let audioSessionUseCase = MockAudioSessionUseCase(
            isBluetoothAudioRouteAvailable: false,
            currentSelectedAudioPort: .builtInSpeaker,
            onAudioSessionRouteChangeSubject: onAudioSessionRouteChangeSubject
        )
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        onAudioSessionRouteChangeSubject.send(.categoryChange)
        
        evaluate {
            sut.speakerOnIcon == .callControlSpeakerEnabled
        }
    }
    
    @MainActor
    func testSpeakerOnIcon_forSelectedPortOhterAndBluetoothAudioRouteAvailable_shouldBeSpeakerOnBluetoothIcon() {
        let onAudioSessionRouteChangeSubject = PassthroughSubject<AudioSessionRouteChangedReason, Never>()
        let audioSessionUseCase = MockAudioSessionUseCase(
            isBluetoothAudioRouteAvailable: true,
            currentSelectedAudioPort: .other,
            onAudioSessionRouteChangeSubject: onAudioSessionRouteChangeSubject
        )
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        onAudioSessionRouteChangeSubject.send(.categoryChange)
        
        evaluate {
            sut.speakerOnIcon == .speakerOnBluetooth
        }
    }
    
    @MainActor
    func testSpeakerOnIcon_forSelectedPortOhterAndBluetoothAudioRouteNotAvailable_shouldBeSpeakerOnIcon() {
        let onAudioSessionRouteChangeSubject = PassthroughSubject<AudioSessionRouteChangedReason, Never>()
        let audioSessionUseCase = MockAudioSessionUseCase(
            isBluetoothAudioRouteAvailable: false,
            currentSelectedAudioPort: .other,
            onAudioSessionRouteChangeSubject: onAudioSessionRouteChangeSubject
        )
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        onAudioSessionRouteChangeSubject.send(.categoryChange)
        
        evaluate {
            sut.speakerOnIcon == .callControlSpeakerEnabled
        }
    }
    
    @MainActor
    func testTapJoinAction_onGuestUserSetup_shouldTrackerEvent() {
        let tracker = MockTracker()
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase, tracker: tracker)
        
        sut.tapJoinAction(firstName: "First", lastName: "Last")
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingJoinGuestButtonEvent()
            ]
        )
    }
    
    @MainActor
    func testShowHostDidNotRespondAlert_onTimeout_shouldTrackerEvent() async {
        let scheduledMeeting = ScheduledMeetingEntity(chatId: 100)
        let callEntity = CallEntity(status: .waitingRoom, chatId: 100, termCodeType: .waitingRoomTimeout)
        let tracker = MockTracker()
        let callUpdateUseCase = MockCallUpdateUseCase()
        let sut = WaitingRoomViewModel(
            scheduledMeeting: scheduledMeeting,
            callUpdateUseCase: callUpdateUseCase,
            tracker: tracker
        )

        XCTAssertEqual(sut.viewState, .waitForHostToLetIn)
        
        callUpdateUseCase.sendCallUpdate(callEntity)

        await Task.megaYield()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                WaitingRoomTimeoutEvent()
            ]
        )
    }
    
    // MARK: - Private methods
    
    private func sampleDate(from string: String = "12/06/2023 09:10") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        return dateFormatter.date(from: string)
    }
    
    private func calculateVideoSize(by screenHeight: CGFloat, isLandscape: Bool) -> CGSize {
        let videoAspectRatio = isLandscape ? 424.0 / 236.0 : 236.0 / 424.0
        let videoHeight = screenHeight - (isLandscape ? 66.0 : 332.0)
        let videoWidth = videoHeight * videoAspectRatio
        return CGSize(width: videoWidth, height: videoHeight)
    }
}

// MARK: - MockWaitingRoomViewRouter

final class MockWaitingRoomViewRouter: WaitingRoomViewRouting {
    var dismiss_calledTimes = 0
    var showLeaveAlert_calledTimes = 0
    var showMeetingInfo_calledTimes = 0
    var showVideoPermissionError_calledTimes = 0
    var showAudioPermissionError_calledTimes = 0
    var showHostDenyAlert_calledTimes = 0
    var showHostDidNotRespondAlert_calledTimes = 0
    var openCallUI_calledTimes = 0
    
    nonisolated init() {}
    
    func dismiss(completion: (() -> Void)?) {
        dismiss_calledTimes += 1
    }
    
    func showLeaveAlert(leaveAction: @escaping () -> Void) {
        showLeaveAlert_calledTimes += 1
    }
    
    func showMeetingInfo() {
        showMeetingInfo_calledTimes += 1
    }
    
    func showVideoPermissionError() {
        showVideoPermissionError_calledTimes += 1
    }
    
    func showAudioPermissionError() {
        showAudioPermissionError_calledTimes += 1
    }
    
    func showHostDenyAlert(leaveAction: @escaping () -> Void) {
        showHostDenyAlert_calledTimes += 1
    }
    
    func showHostDidNotRespondAlert(leaveAction: @escaping () -> Void) {
        showHostDidNotRespondAlert_calledTimes += 1
    }
    
    func openCallUI(for call: CallEntity, in chatRoom: ChatRoomEntity, isSpeakerEnabled: Bool) {
        openCallUI_calledTimes += 1
    }
}
