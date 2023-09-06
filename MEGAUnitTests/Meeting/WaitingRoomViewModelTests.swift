import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class WaitingRoomViewModelTests: XCTestCase {
    func testMeetingTitle_onLoadWaitingRoom_shouldMatch() {
        let meetingTitle = "Test Meeting"
        let scheduledMeeting = ScheduledMeetingEntity(title: meetingTitle)
        let sut = WaitingRoomViewModel(scheduledMeeting: scheduledMeeting)
        
        XCTAssertEqual(sut.meetingTitle, meetingTitle)
    }
    
    func testMeetingDate_givenMeetingStartAndEndDate_shouldMatch() throws {
        let startDate = try XCTUnwrap(sampleDate(from: "21/09/2023 10:30"))
        let endDate = try XCTUnwrap(sampleDate(from: "21/09/2023 10:45"))
        let scheduledMeeting = ScheduledMeetingEntity(startDate: startDate, endDate: endDate)
        let sut = WaitingRoomViewModel(scheduledMeeting: scheduledMeeting)
        
        XCTAssertEqual(sut.createMeetingDate(), "Thu, 21 Sep ·10:30-10:45")
    }
    
    func testViewState_onLoadWaitingRoomAndIsGuest_shouldBeGuestJoinState() {
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
        XCTAssertEqual(sut.viewState, .guestJoin)
    }
    
    func testViewState_onLoadWaitingRoomAndIsNotGuestAndMeetingNotStart_shouldBeWaitForHostToStartState() {
        let callUseCase = MockCallUseCase(call: nil)
        let sut = WaitingRoomViewModel(callUseCase: callUseCase)
        XCTAssertEqual(sut.viewState, .waitForHostToStart)
    }
    
    func testViewState_onLoadWaitingRoomAndIsNotGuestAndMeetingDidStart_shouldBeWaitForHostToStartState() {
        let sut = WaitingRoomViewModel()
        XCTAssertEqual(sut.viewState, .waitForHostToLetIn)
    }
    
    func testViewState_onMeetingNotStartTransitsToMeetingDidStart_shouldChangeFromWaitForHostToStartToWaitForHostToLetIn() {
        let scheduledMeeting = ScheduledMeetingEntity(chatId: 100)
        let chatCallStatusUpdatePublisher = PassthroughSubject<CallEntity, Never>()
        let chatUseCase = MockChatUseCase(chatCallStatusUpdatePublisher: chatCallStatusUpdatePublisher)
        let callEntity = CallEntity(status: .connecting, chatId: 100)
        let callUseCase = MockCallUseCase(call: nil, answerCallCompletion: .success(callEntity))
        let sut = WaitingRoomViewModel(scheduledMeeting: scheduledMeeting, chatUseCase: chatUseCase, callUseCase: callUseCase)
        
        XCTAssertEqual(sut.viewState, .waitForHostToStart)
        
        callUseCase.call = callEntity
        chatCallStatusUpdatePublisher.send(callEntity)
        
        evaluate {
            sut.viewState == .waitForHostToLetIn
        }
    }
    
    func testViewState_onMeetingDidStartTransitsToMeetingNotStart_shouldChangeFromWaitForHostToLetInToWaitForHostToStart() {
        let scheduledMeeting = ScheduledMeetingEntity(chatId: 100)
        let chatCallStatusUpdatePublisher = PassthroughSubject<CallEntity, Never>()
        let chatUseCase = MockChatUseCase(isCallActive: true, chatCallStatusUpdatePublisher: chatCallStatusUpdatePublisher)
        let callUseCase = MockCallUseCase()
        let sut = WaitingRoomViewModel(scheduledMeeting: scheduledMeeting, chatUseCase: chatUseCase, callUseCase: callUseCase)
        
        XCTAssertEqual(sut.viewState, .waitForHostToLetIn)
        
        callUseCase.call = nil
        chatCallStatusUpdatePublisher.send(CallEntity(status: .terminatingUserParticipation, chatId: 100))
        
        evaluate {
            sut.viewState == .waitForHostToStart
        }
    }
    
    func testSpeakerButton_onTapSpeakerButton_shouldDisableSpeakerButton() {
        let audioSessionUseCase = MockAudioSessionUseCase()
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        sut.enableLoudSpeaker(enabled: false)
        
        XCTAssertEqual(audioSessionUseCase.disableLoudSpeaker_calledTimes, 1)
    }
    
    func testLeaveButton_didTapLeaveButton_shouldPresentLeaveAlert() {
        let router = MockWaitingRoomViewRouter()
        let sut = WaitingRoomViewModel(router: router)
        
        sut.leaveButtonTapped()
        
        XCTAssertEqual(router.showLeaveAlert_calledTimes, 1)
    }
    
    func testMeetingInfoButton_didTapMeetingInfoButton_shouldPresentMeetingInfo() {
        let router = MockWaitingRoomViewRouter()
        let sut = WaitingRoomViewModel(router: router)
        
        sut.infoButtonTapped()
        
        XCTAssertEqual(router.showMeetingInfo_calledTimes, 1)
    }
    
    func testCalculateVideoSize_portraitMode_shouldMatch() {
        let screenHeight = 424.0
        let screenWidth = 236.0
        let sut = WaitingRoomViewModel()
        sut.screenSize = CGSize(width: screenWidth, height: screenHeight)
        
        let videoSize = sut.calculateVideoSize()
        
        XCTAssertEqual(videoSize, calculateVideoSize(by: screenHeight, isLandscape: false))
    }
    
    func testCalculateVideoSize_landscapeMode_shouldMatch() {
        let screenHeight = 236.0
        let screenWidth = 424.0
        let sut = WaitingRoomViewModel()
        sut.screenSize = CGSize(width: screenWidth, height: screenHeight)
        
        let videoSize = sut.calculateVideoSize()
        
        XCTAssertEqual(videoSize, calculateVideoSize(by: screenHeight, isLandscape: true))
    }
    
    func testCalculateBottomPanelHeight_portraitModeAndGuestJoin_shouldMatch() {
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
        
        XCTAssertEqual(sut.calculateBottomPanelHeight(), 142.0)
    }
    
    func testCalculateBottomPanelHeight_portraitModeAndWaitForHostToLetIn_shouldMatch() {
        let sut = WaitingRoomViewModel()
        
        XCTAssertEqual(sut.calculateBottomPanelHeight(), 100.0)
    }
    
    func testCalculateBottomPanelHeight_landscapeModeAndGuestJoin_shouldMatch() {
        let screenHeight = 236.0
        let screenWidth = 424.0
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
        sut.screenSize = CGSize(width: screenWidth, height: screenHeight)
        
        XCTAssertEqual(sut.calculateBottomPanelHeight(), 142.0)
    }
    
    func testCalculateBottomPanelHeight_landscapeModeAndWaitForHostToLetIn_shouldMatch() {
        let screenHeight = 236.0
        let screenWidth = 424.0
        let sut = WaitingRoomViewModel()
        sut.screenSize = CGSize(width: screenWidth, height: screenHeight)
        
        XCTAssertEqual(sut.calculateBottomPanelHeight(), 8.0)
    }
    
    func testShowWaitingRoomMessage_whenGuestLogin_shouldNotShow() {
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
        
        XCTAssertFalse(sut.showWaitingRoomMessage)
    }
    
    func testShowWaitingRoomMessage_whenWaitForHostToStart_shouldShow() {
        let chatUseCase = MockChatUseCase(isCallActive: false)
        let sut = WaitingRoomViewModel(chatUseCase: chatUseCase)
        
        XCTAssertTrue(sut.showWaitingRoomMessage)
    }
    
    func testShowWaitingRoomMessage_whenWaitForHostToLetIn_shouldShow() {
        let chatUseCase = MockChatUseCase(isCallActive: true)
        let sut = WaitingRoomViewModel(chatUseCase: chatUseCase)
        
        XCTAssertTrue(sut.showWaitingRoomMessage)
    }
    
    func testWaitingRoomMessage_whenWaitForHostToStart_shouldMatch() {
        let callUseCase = MockCallUseCase(call: nil)
        let sut = WaitingRoomViewModel(callUseCase: callUseCase)
        
        XCTAssertEqual(sut.waitingRoomMessage, Strings.Localizable.Meetings.WaitingRoom.Message.waitForHostToStartTheMeeting)
    }
    
    func testWaitingRoomMessage_whenWaitForHostToLetIn_shouldMatch() {
        let sut = WaitingRoomViewModel()
        
        XCTAssertEqual(sut.waitingRoomMessage, Strings.Localizable.Meetings.WaitingRoom.Message.waitForHostToLetYouIn)
    }
    
    func testTapJoinAction_onCreateEphemeralAccountSuccessAndJoinChatSuccessAndMeetingDidStart_shoudBecomeWaitForHostToLetIn() {
        let callUseCase = MockCallUseCase(call: CallEntity(), answerCallCompletion: .success(CallEntity()))
        let meetingUseCase = MockMeetingCreatingUseCase(createEpehemeralAccountCompletion: .success, joinChatCompletion: .success(ChatRoomEntity()))
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(callUseCase: callUseCase,
                                       meetingUseCase: meetingUseCase,
                                       accountUseCase: accountUseCase,
                                       chatLink: "Test chatLink")
        
        XCTAssertEqual(sut.viewState, .guestJoin)
        
        sut.tapJoinAction(firstName: "First", lastName: "Last")
        
        evaluate {
            sut.viewState == .waitForHostToLetIn
        }
    }
    
    func testTapJoinAction_onCreateEphemeralAccountSuccessAndJoinChatSuccessAndMeetingNotStart_shoudBecomeWaitForHostToStart() {
        let callUseCase = MockCallUseCase(call: nil, answerCallCompletion: .success(CallEntity()))
        let meetingUseCase = MockMeetingCreatingUseCase(createEpehemeralAccountCompletion: .success, joinChatCompletion: .success(ChatRoomEntity()))
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(callUseCase: callUseCase,
                                       meetingUseCase: meetingUseCase,
                                       accountUseCase: accountUseCase,
                                       chatLink: "Test chatLink")
        
        XCTAssertEqual(sut.viewState, .guestJoin)
        
        sut.tapJoinAction(firstName: "First", lastName: "Last")
        
        evaluate {
            sut.viewState == .waitForHostToStart
        }
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
    
    private func evaluate(isInverted: Bool = false, expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        expectation.isInverted = isInverted
        wait(for: [expectation], timeout: 5)
    }
}

final class MockWaitingRoomViewRouter: WaitingRoomViewRouting {
    var dismiss_calledTimes = 0
    var showLeaveAlert_calledTimes = 0
    var showMeetingInfo_calledTimes = 0
    var showVideoPermissionError_calledTimes = 0
    var showAudioPermissionError_calledTimes = 0
    var showHostDenyAlert_calledTimes = 0
    var hostAllowToJoin_calledTimes = 0
    
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
    
    func hostAllowToJoin() {
        hostAllowToJoin_calledTimes += 1
    }
}
