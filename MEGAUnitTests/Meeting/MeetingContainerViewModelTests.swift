import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class MeetingContainerViewModelTests: XCTestCase {
    
    var viewModel: MeetingContainerViewModel!

    func testAction_onViewReady() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        viewModel = MeetingContainerViewModel(
            router: router,
            chatRoom: chatRoom
        )
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [])
        XCTAssert(router.showMeetingUI_calledTimes == 1)
    }
    
    func testAction_hangCall_attendeeIsGuest() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callEntity = CallEntity(chatId: 1, callId: 1, duration: 1, initialTimestamp: 1, finalTimestamp: 1, numberOfParticipants: 1)
        let callUseCase = MockCallUseCase(call: callEntity)
        viewModel = MeetingContainerViewModel(router: router,
                                                  chatRoom: chatRoom,
                                                  callUseCase: callUseCase,
                                                  accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: true, isLoggedIn: false))
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(router.showEndMeetingOptions_calledTimes == 1)
    }
    
    func testAction_hangCall_attendeeIsParticipantOrModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let callEntity = CallEntity(chatId: 1, callId: 1, duration: 1, initialTimestamp: 1, finalTimestamp: 1, numberOfParticipants: 1)
        let callUseCase = MockCallUseCase(call: callEntity)
        let callManager = MockCallManager()
        viewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, callManager: callManager)
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(callManager.endCall_CalledTimes == 1)
    }
    
    func testAction_backButtonTap() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)
        test(viewModel: viewModel, action: .tapOnBackButton, expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
    }
    
    func testAction_ChangeMenuVisibility() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)
        test(viewModel: viewModel, action: .changeMenuVisibility, expectedCommands: [])
        XCTAssert(router.toggleFloatingPanel_CalledTimes == 1)
    }

    func testAction_shareLink_Success() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let chatRoomUseCase = MockChatRoomUseCase(publicLinkCompletion: .success("https://mega.link"))
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, chatRoomUseCase: chatRoomUseCase)
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton(), completion: nil), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 1)
    }
    
    func testAction_shareLink_Failure() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton(), completion: nil), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 0)
    }
    
    func testAction_displayParticipantInMainView() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        test(viewModel: viewModel, action: .displayParticipantInMainView(particpant), expectedCommands: [])
        XCTAssert(router.displayParticipantInMainView_calledTimes == 1)
    }
    
    func testAction_didDisplayParticipantInMainView() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        test(viewModel: viewModel, action: .didDisplayParticipantInMainView(particpant), expectedCommands: [])
        XCTAssert(router.didDisplayParticipantInMainView_calledTimes == 1)
    }
    
    func testAction_didSwitchToGridView() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)
        test(viewModel: viewModel, action: .didSwitchToGridView, expectedCommands: [])
        XCTAssert(router.didSwitchToGridView_calledTimes == 1)
    }
    
    func testAction_showEndCallDialog() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callEntity = CallEntity(numberOfParticipants: 1, participants: [100])
        let callUseCase = MockCallUseCase(call: callEntity)
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: callUseCase)
        test(viewModel: viewModel, action: .showEndCallDialogIfNeeded, expectedCommands: [])
        XCTAssert(router.didShowEndDialog_calledTimes == 1)
    }
    
    func testAction_removeEndCallDialogWhenParticipantAdded() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()

        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)
        test(viewModel: viewModel, action: .participantAdded, expectedCommands: [])
        XCTAssert(router.removeEndDialog_calledTimes == 1)
    }
    
    func testAction_removeEndCallDialogAndEndCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)
        test(viewModel: viewModel, action: .removeEndCallAlertAndEndCall, expectedCommands: [])
        XCTAssert(router.removeEndDialog_calledTimes == 1)
    }
    
    func testAction_removeEndCallDialogWhenParticipantJoinWaitingRoom() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()

        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)
        test(viewModel: viewModel, action: .participantJoinedWaitingRoom, expectedCommands: [])
        XCTAssert(router.removeEndDialog_calledTimes == 1)
    }
    
    func testAction_showJoinMegaScreen() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)
        test(viewModel: viewModel, action: .showJoinMegaScreen, expectedCommands: [])
        XCTAssert(router.showJoinMegaScreen_calledTimes == 1)
    }
    
    func testAction_OnViewReady_NoUserJoined() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity(numberOfParticipants: 1, participants: [100]))
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let expectation = expectation(description: "testAction_OnViewReady_NoUserJoined")
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, noUserJoinedUseCase: noUserJoinedUseCase)
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [])
        
        var subscription: AnyCancellable? = noUserJoinedUseCase
            .monitor
            .receive(on: DispatchQueue.main)
            .sink { _ in
            expectation.fulfill()
        }
        
        _ = subscription // suppress never used warning
        
        noUserJoinedUseCase.start(timerDuration: 1, chatId: 101)
        waitForExpectations(timeout: 10)
        XCTAssert(router.didShowEndDialog_calledTimes == 1)
        subscription = nil
    }
    
    func testAction_muteMicrophoneForMeetingsWhenLastParticipantLeft() {
        let chatRoom = ChatRoomEntity(chatType: .meeting)
        let chatRoomUsecase = MockChatRoomUseCase(chatRoomEntity: chatRoom)

        let call = CallEntity(hasLocalAudio: true, numberOfParticipants: 1, participants: [100])
        let callUseCase = MockCallUseCase(call: call)
        let callManager = MockCallManager()
        viewModel = MeetingContainerViewModel(callUseCase: callUseCase,
                                              chatRoomUseCase: chatRoomUsecase,
                                              accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                              callManager: callManager)
        
        test(viewModel: viewModel, action: .participantRemoved, expectedCommands: [])
        XCTAssertTrue(callManager.muteCall_CalledTimes == 1)
    }
    
    func testAction_muteMicrophoneForGroupWhenLastParticipantLeft() {
        let chatRoom = ChatRoomEntity(chatType: .group)
        let chatRoomUsecase = MockChatRoomUseCase(chatRoomEntity: chatRoom)

        let call = CallEntity(hasLocalAudio: true, numberOfParticipants: 1, participants: [100])
        let callUseCase = MockCallUseCase(call: call)
        
        let callManager = MockCallManager()
        viewModel = MeetingContainerViewModel(callUseCase: callUseCase,
                                              chatRoomUseCase: chatRoomUsecase,
                                              accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                              callManager: callManager)
        
        test(viewModel: viewModel, action: .participantRemoved, expectedCommands: [])
        XCTAssertTrue(callManager.muteCall_CalledTimes == 1)
    }
    
    func testAction_donotMuteMicrophoneForOneToOneWhenLastParticipantLeft() {
        let chatRoom = ChatRoomEntity(chatType: .oneToOne)
        let chatRoomUsecase = MockChatRoomUseCase(chatRoomEntity: chatRoom)

        let call = CallEntity(hasLocalAudio: true, numberOfParticipants: 1, participants: [100])
        let callUseCase = MockCallUseCase(call: call)
        
        let callManager = MockCallManager()

        viewModel = MeetingContainerViewModel(callUseCase: callUseCase,
                                              chatRoomUseCase: chatRoomUsecase,
                                              accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                              callManager: callManager)
        
        test(viewModel: viewModel, action: .participantRemoved, expectedCommands: [])
        XCTAssertTrue(callManager.muteCall_CalledTimes == 0)
    }
    
    func testAction_endCallForAll() {
        let chatRoom = ChatRoomEntity(chatType: .meeting)
        let callManager = MockCallManager()
        viewModel = MeetingContainerViewModel(chatRoom: chatRoom, callManager: callManager)

        test(viewModel: viewModel, action: .endCallForAll, expectedCommands: [])
        XCTAssert(callManager.endCall_CalledTimes == 1)
    }
    
    func testHangCall_forNonGuest_shouldResetCallToUnmute() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callEntity = CallEntity(chatId: 1, callId: 1, duration: 1, initialTimestamp: 1, finalTimestamp: 1, numberOfParticipants: 1)
        let callUseCase = MockCallUseCase(call: callEntity)
        let accountUseCase = MockAccountUseCase(isGuest: false)
        let callManager = MockCallManager()
        viewModel = MeetingContainerViewModel(
            router: router,
            chatRoom: chatRoom,
            callUseCase: callUseCase,
            accountUseCase: accountUseCase,
            callManager: callManager
        )
        test(viewModel: viewModel,
             action: .hangCall(
                presenter: UIViewController(),
                sender: UIButton()
             ),
             expectedCommands: [])
        XCTAssertEqual(callManager.muteCall_CalledTimes, 0)
    }
    
    func testAction_mutedByClient_shouldShowMutedMessage() {
        let chatRoom = ChatRoomEntity(chatType: .meeting)
        let router = MockMeetingContainerRouter()
        viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom)

        test(viewModel: viewModel, action: .showMutedBy("Host name"), expectedCommands: [])
        XCTAssert(router.showMutedMessage_calledTimes == 1)
    }
    
    func testSfuProtocolErrorReceived_shouldShowUpdateAppAlert() {
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity(status: .connecting, changeType: .status, numberOfParticipants: 1, participants: [100]))
        viewModel = MeetingContainerViewModel(router: router, callUseCase: callUseCase)

        callUseCase.callUpdateSubject.send(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .protocolVersion, numberOfParticipants: 1, participants: [100]))
        evaluate {
            router.showProtocolErrorAlert_calledTimes == 1
        }
    }
    
    func testUsersLimitErrorReceived_loggedUser_shouldShowFreeAccountLimitAlert() {
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity(status: .connecting, changeType: .status, numberOfParticipants: 1, participants: [100]))
        viewModel = MeetingContainerViewModel(router: router, callUseCase: callUseCase)

        callUseCase.callUpdateSubject.send(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callUsersLimit, numberOfParticipants: 1, participants: [100]))
        evaluate {
            router.showUsersLimitErrorAlert_calledTimes == 1
        }
    }
    
    func testUsersLimitErrorReceived_isGuestUser_shouldShowFreeAccountLimitAlertAndTackEvent() {
        let router = MockMeetingContainerRouter()
        let tracker = MockTracker()
        let callUseCase = MockCallUseCase(call: CallEntity(status: .connecting, changeType: .status, numberOfParticipants: 1, participants: [100]))
        viewModel = MeetingContainerViewModel(router: router, callUseCase: callUseCase, accountUseCase: MockAccountUseCase(isGuest: true), tracker: tracker)

        callUseCase.callUpdateSubject.send(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callUsersLimit, numberOfParticipants: 1, participants: [100]))
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [IOSGuestEndCallFreePlanUsersLimitDialogEvent()]
        )
        
        evaluate {
            router.showUsersLimitErrorAlert_calledTimes == 1
        }
    }
    
    func testTooManyParticipantsErrorReceived_shouldDismissCall() {
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity(status: .connecting, changeType: .status, numberOfParticipants: 1, participants: [100]))
        viewModel = MeetingContainerViewModel(router: router, callUseCase: callUseCase)

        callUseCase.callUpdateSubject.send(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .tooManyParticipants, numberOfParticipants: 1, participants: [100]))
        evaluate {
            router.dismiss_calledTimes == 1
        }
    }
    
    // MARK: - Private methods
    private func evaluate(expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 5)
    }

    func testCallUpdate_callWillEndReceivedUserIsModerator_shouldshowCallWillEndAlert() {
        let (sut, router) = makeSUT(
            chatRoom: ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        )
        test(viewModel: sut,
             action: .showCallWillEndAlert(timeToEndCall: 10, completion: { _ in }),
             expectedCommands: [])
        XCTAssertEqual(router.showCallWillEndAlert_calledTimes, 1)
    }
    
    func testCallUpdate_callDestroyedUserIsCaller_shouldShowUpgradeToPro() {
        let callUseCase = MockCallUseCase()

        let (sut, router) = makeSUT(
            callUseCase: callUseCase,
            accountUseCase: MockAccountUseCase(currentAccountDetails: AccountDetailsEntity.build())
        )
        viewModel = sut

        callUseCase.callUpdateSubject.send(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callDurationLimit, isOwnClientCaller: true))

        evaluate {
            router.showUpgradeToProDialog_calledTimes == 1
        }
    }
    
    func testCallUpdate_callDestroyedUserIsNotCaller_shouldNotShowUpgradeToPro() {
        let callUseCase = MockCallUseCase()

        let (sut, router) = makeSUT(
            callUseCase: callUseCase,
            accountUseCase: MockAccountUseCase(currentAccountDetails: AccountDetailsEntity.build())
        )
        viewModel = sut

        callUseCase.callUpdateSubject.send(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callDurationLimit))

        evaluate {
            router.showUpgradeToProDialog_calledTimes == 0 &&
            router.dismiss_calledTimes == 1
        }
    }
    
    private func makeSUT(
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(call: CallEntity()),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
        authUseCase: some AuthUseCaseProtocol = MockAuthUseCase(),
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol = MockMeetingNoUserJoinedUseCase(),
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol =  MockAnalyticsEventUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callManager: some CallManagerProtocol = MockCallManager(),
        tracker: some AnalyticsTracking = MockTracker(),
        featureFlag: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> (MeetingContainerViewModel, MockMeetingContainerRouter) {
        
        let router = MockMeetingContainerRouter()
        return (
            MeetingContainerViewModel(
                router: router,
                chatRoom: chatRoom,
                callUseCase: callUseCase,
                chatRoomUseCase: chatRoomUseCase,
                chatUseCase: chatUseCase,
                scheduledMeetingUseCase: scheduledMeetingUseCase,
                accountUseCase: accountUseCase,
                authUseCase: authUseCase,
                noUserJoinedUseCase: noUserJoinedUseCase,
                analyticsEventUseCase: analyticsEventUseCase,
                megaHandleUseCase: megaHandleUseCase,
                callManager: callManager,
                tracker: tracker,
                featureFlagProvider: featureFlag
            ),
            router
        )
    }
}

final class MockMeetingContainerRouter: MeetingContainerRouting {
    var showMeetingUI_calledTimes = 0
    var dismiss_calledTimes = 0
    var toggleFloatingPanel_CalledTimes = 0
    var showEndMeetingOptions_calledTimes = 0
    var showOptionsMenu_calledTimes = 0
    var shareLink_calledTimes = 0
    var renameChat_calledTimes = 0
    var showMeetingError_calledTimes = 0
    var enableSpeaker_calledTimes = 0
    var displayParticipantInMainView_calledTimes = 0
    var didDisplayParticipantInMainView_calledTimes = 0
    var didSwitchToGridView_calledTimes = 0
    var didShowEndDialog_calledTimes = 0
    var removeEndDialog_calledTimes = 0
    var showJoinMegaScreen_calledTimes = 0
    var showHangOrEndCallDialog_calledTimes = 0
    var selectWaitingRoomList_calledTimes = 0
    var showScreenShareWarning_calledTimes = 0
    var showMutedMessage_calledTimes = 0
    var showProtocolErrorAlert_calledTimes = 0
    var showUsersLimitErrorAlert_calledTimes = 0
    var showCallWillEndAlert_calledTimes = 0
    var showUpgradeToProDialog_calledTimes = 0

    func showMeetingUI(containerViewModel: MeetingContainerViewModel) {
        showMeetingUI_calledTimes += 1
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        toggleFloatingPanel_CalledTimes += 1
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        dismiss_calledTimes += 1
        completion?()
    }
    
    func showEndMeetingOptions(presenter: UIViewController, meetingContainerViewModel: MeetingContainerViewModel, sender: UIButton) {
        showEndMeetingOptions_calledTimes += 1
    }
    
    func showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool, containerViewModel: MeetingContainerViewModel) {
        showEndMeetingOptions_calledTimes += 1
    }
    
    func showShareChatLinkActivity(presenter: UIViewController?, sender: AnyObject, link: String, metadataItemSource: ChatLinkPresentationItemSource, isGuestAccount: Bool, completion: UIActivityViewController.CompletionWithItemsHandler?) {
        shareLink_calledTimes += 1
    }
    
    func renameChat() {
        renameChat_calledTimes += 1
    }
    
    func showShareMeetingError() {
        showMeetingError_calledTimes += 1
    }
    
    func enableSpeaker(_ enable: Bool) {
        enableSpeaker_calledTimes += 1
    }
    
    func displayParticipantInMainView(_ participant: CallParticipantEntity) {
        displayParticipantInMainView_calledTimes += 1
    }
    
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity) {
        didDisplayParticipantInMainView_calledTimes += 1
    }
    
    func didSwitchToGridView() {
        didSwitchToGridView_calledTimes += 1
    }
    
    func showEndCallDialog(endCallCompletion: @escaping () -> Void, stayOnCallCompletion: (() -> Void)?) {
        didShowEndDialog_calledTimes += 1
    }
    
    func removeEndCallDialog(finishCountDown: Bool, completion: (() -> Void)?) {
        removeEndDialog_calledTimes += 1
    }
    
    func showJoinMegaScreen() {
        showJoinMegaScreen_calledTimes += 1
    }
    
    func showHangOrEndCallDialog(containerViewModel: MeetingContainerViewModel) {
        showHangOrEndCallDialog_calledTimes += 1
    }
    
    func selectWaitingRoomList(containerViewModel: MeetingContainerViewModel) {
        selectWaitingRoomList_calledTimes += 1
    }
    
    func showScreenShareWarning() {
        showScreenShareWarning_calledTimes += 1
    }
    
    func showMutedMessage(by name: String) {
        showMutedMessage_calledTimes += 1
    }
    
    func showProtocolErrorAlert() {
        showProtocolErrorAlert_calledTimes += 1
    }
    
    func showUsersLimitErrorAlert() {
        showUsersLimitErrorAlert_calledTimes += 1
    }
    
    func showCallWillEndAlert(timeToEndCall: Double, completion: ((Double) -> Void)?) {
        showCallWillEndAlert_calledTimes += 1
    }
    
    func showUpgradeToProDialog(_ account: MEGADomain.AccountDetailsEntity) {
        showUpgradeToProDialog_calledTimes += 1
    }
}
