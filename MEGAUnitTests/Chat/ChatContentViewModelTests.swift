@testable import Chat
import ChatRepoMock
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class ChatContentViewModelTests: XCTestCase {
    
    @MainActor func testStartOrJoinCall_hideStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .startOrJoinCallCleanUp,
             expectedCommands: [.configureStartOrJoinCallButton(sut.titleForStartOrJoinCallButton, true)])
    }
    
    @MainActor func testUpdateCallNavigationBarButtons_callUpdateCallBarButtons() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateCallNavigationBarButtons,
             expectedCommands: [.enableAudioVideoButtons(false)])
    }
    
    @MainActor func testStartCallBarButtonTapped_audioCall_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callController = MockCallController()
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil, callCompletion: .success(CallEntity())),
            callController: callController
        )
        
        test(viewModel: sut, action: .startCallBarButtonTapped(isVideoEnabled: false),
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 1)
    }
    
    @MainActor func testStartCallBarButtonTapped_audioCallNoAudioGranted_dontShowCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callController = MockCallController()
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil),
            permissionRouter: MockPermissionAlertRouter(isAudioPermissionGranted: false),
            callController: callController
        )
        
        test(viewModel: sut, action: .startCallBarButtonTapped(isVideoEnabled: false),
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 0)
    }
    
    @MainActor func testStartCallBarButtonTapped_videoCall_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callController = MockCallController()
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil, callCompletion: .success(CallEntity())),
            callController: callController
        )
        
        test(viewModel: sut, action: .startCallBarButtonTapped(isVideoEnabled: true),
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 1)
    }
    
    @MainActor func testStartCallBarButtonTapped_videoCallNoVideoGranted_dontShowCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callController = MockCallController()
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil),
            permissionRouter: MockPermissionAlertRouter(isVideoPermissionGranted: false),
            callController: callController
        )
        
        test(viewModel: sut, action: .startCallBarButtonTapped(isVideoEnabled: true),
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 0)
    }
    
    @MainActor func testStartOrJoinFloatingButtonTapped_existsOtherCallInProgres_showCallAlreadyInProgress() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(isExistingActiveCall: true, currentChatConnectionStatus: .online)
        let callUseCase = MockCallUseCase(call: CallEntity(status: .userNoPresent))
        let callController = MockCallController()
        let (sut, router) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callController: callController
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 0)
        XCTAssert(router.showCallAlreadyInProgress_calledTimes == 1)
    }
    
    @MainActor func testStartOrJoinFloatingButtonTapped_startCall_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callController = MockCallController()
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil, callCompletion: .success(CallEntity())),
            callController: callController
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 1)
    }
    
    @MainActor func testStartOrJoinFloatingButtonTapped_answerRingingCall_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let call = CallEntity(isRinging: true)
        let callUseCase = MockCallUseCase(call: call, answerCallCompletion: .success(call))
        let callController = MockCallController()
        let callsManager = MockCallsManager()
        callsManager.addCall(CallActionSync(chatRoom: chatRoom), withUUID: .testUUID)
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callController: callController,
            callsManager: callsManager
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callController.answerCall_CalledTimes == 1)
    }
    
    @MainActor func testReturnToCallBannerButtonTapped_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let (sut, router) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase
        )

        test(viewModel: sut, action: .returnToCallBannerButtonTapped,
             expectedCommands: [])
        XCTAssert(router.startCallUI_calledTimes == 1)
    }
    
    @MainActor func testReturnToCallBannerButtonTapped_WaitingRoomEnabledUserStandard_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let (sut, router) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase
        )

        test(viewModel: sut, action: .returnToCallBannerButtonTapped,
             expectedCommands: [])
        XCTAssert(router.startCallUI_calledTimes == 1)
    }
    
    @MainActor func testReturnToCallBannerButtonTapped_WaitingRoomEnabledUserModerator_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let (sut, router) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase
        )

        test(viewModel: sut, action: .returnToCallBannerButtonTapped,
             expectedCommands: [])
        XCTAssert(router.startCallUI_calledTimes == 1)
    }
    
    @MainActor func testStartOrJoinFloatingButtonTapped_startCall_openWaitingRoom() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callController = MockCallController()
        let (sut, router) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil),
            scheduledMeetingUseCase: MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()]),
            callController: callController
        )

        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 0)
        XCTAssert(router.openWaitingRoom_calledTimes == 1)
    }
    
    @MainActor func testStartOrJoinFloatingButtonTapped_startCallWaitingRoomEnabledUserModerator_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callController = MockCallController()
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil, callCompletion: .success(CallEntity())),
            callController: callController
        )

        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 1)
    }
    
    @MainActor func testStartOrJoinFloatingButtonTapped_joinCallInProgress_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let call = CallEntity(status: .userNoPresent)
        let callUseCase = MockCallUseCase(call: call, answerCallCompletion: .success(call))
        let callController = MockCallController()
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callController: callController
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 1)
    }
    
    @MainActor func testStartOrJoinFloatingButtonTapped_joinCallInProgressWaitingRoomEnabledUserModerator_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let call = CallEntity(status: .userNoPresent)
        let callUseCase = MockCallUseCase(call: call, answerCallCompletion: .success(call))
        let callController = MockCallController()
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callController: callController
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 1)
    }
    
    @MainActor func testStartOrJoinFloatingButtonTapped_joinCallInProgressWaitingRoomEnabledUserStandard_openWaitingRoom() {
        let callController = MockCallController()
        let (sut, router) = makeChatContentViewModel(
            chatRoom: ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true),
            chatUseCase: MockChatUseCase(currentChatConnectionStatus: .online),
            callUseCase: MockCallUseCase(call: CallEntity(status: .userNoPresent)),
            scheduledMeetingUseCase: MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()]),
            callController: callController
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 0)
        XCTAssert(router.openWaitingRoom_calledTimes == 1)
    }
    
    @MainActor func testUpdateContent_callIsNil_shouldCallCleanUpAndUpdateStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase
        )
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.tapToReturnToCallCleanUp, .configureStartOrJoinCallButton(sut.titleForStartOrJoinCallButton, true)])
    }
    
    @MainActor func testUpdateContent_connectionIsNotOnline_shouldCallCleanUpAndUpdateStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.activeCallEntity = CallEntity()
        chatUseCase.currentChatConnectionStatus = .invalid
        
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.tapToReturnToCallCleanUp, .configureStartOrJoinCallButton(sut.titleForStartOrJoinCallButton, true)])
    }
    
    @MainActor func testUpdateContent_joiningTheCall_shouldUpdateNavBarStartOrJoinAndReturnButtons() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.activeCallEntity = CallEntity(status: .joining, chatId: chatRoom.chatId)
        chatUseCase.currentChatConnectionStatus = .online
        
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.configNavigationBar,
                                .configureStartOrJoinCallButton(sut.titleForStartOrJoinCallButton, true),
                                .tapToReturnToCallCleanUp
                               ])
    }
    
    @MainActor func testUpdateContent_callInProgress_shoulHideStartOrJoinAndShowReturnButtons() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        let callEntity = CallEntity(status: .inProgress, chatId: chatRoom.chatId)
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.configNavigationBar,
                                .configureStartOrJoinCallButton(sut.titleForStartOrJoinCallButton, true),
                                .showTapToReturnToCall("Tap to return to call 00:00")
                               ])
    }
    
    @MainActor func testUpdateContent_callInProgressLastPeerLeavesAndUserIsTheOnlyOneInTheCall_shouldShowEndCallDialog() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase(myUserHandle: 100)
        let callEntity = CallEntity(status: .inProgress, chatId: chatRoom.chatId, changeType: .callComposition, numberOfParticipants: 1, participants: [chatUseCase.myUserHandle()])
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let (sut, router) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase
        )
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.configNavigationBar,
                                .configureStartOrJoinCallButton(sut.titleForStartOrJoinCallButton, true),
                                .showTapToReturnToCall("Tap to return to call 00:00")
                               ])
        XCTAssert(router.showEndCallDialog_calledTimes == 1)
    }
    
    @MainActor func testUpdateContent_callInConnecting_shouldCall2Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        let callEntity = CallEntity(status: .connecting, chatId: chatRoom.chatId)
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.configNavigationBar,
                                .showTapToReturnToCall(Strings.Localizable.reconnecting)
                               ])
    }
    
    @MainActor func testUpdateContent_callInDestroyed_shouldUpdateCallButtons() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        let callEntity = CallEntity(status: .destroyed, chatId: chatRoom.chatId)
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.configNavigationBar,
                                .configureStartOrJoinCallButton(sut.titleForStartOrJoinCallButton, true),
                                .tapToReturnToCallCleanUp])
    }
    
    @MainActor func testUpdateCallNavigationBarButtons_forWaitingRoomNonHost_shouldNotEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
        test(
            viewModel: sut,
            action: .updateCallNavigationBarButtons,
            expectedCommands: [
                .enableAudioVideoButtons(false)
            ]
        )
    }
    
    @MainActor func testUpdateCallNavigationBarButtons_forWaitingRoomHost_shouldEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
        test(
            viewModel: sut,
            action: .updateCallNavigationBarButtons,
            expectedCommands: [
                .enableAudioVideoButtons(true)
            ]
        )
    }
    
    @MainActor func testUpdateCallNavigationBarButtons_onPrivilegeChangeFromModeratorToStandard_shouldNotEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
        let newChatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        test(
            viewModel: sut,
            actions: [
                .updateChatRoom(newChatRoom),
                .updateCallNavigationBarButtons
            ],
            expectedCommands: [
                .enableAudioVideoButtons(false)
            ]
        )
    }
    
    @MainActor func testUpdateCallNavigationBarButtons_onPrivilegeChangeFromStandardToModerator_shouldEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
        let newChatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        test(
            viewModel: sut,
            actions: [
                .updateChatRoom(newChatRoom),
                .updateCallNavigationBarButtons
            ],
            expectedCommands: [
                .enableAudioVideoButtons(true)
            ]
        )
    }
    
    @MainActor func testInviteParticipants_onCallAndWaitingRoomEnabledAndModerator_shouldCallAllowUsersJoinCallAndMatchInvitedUsers() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let invitedParticipants: [HandleEntity] = [1]
        test(
            viewModel: sut,
            action: .inviteParticipants(invitedParticipants),
            expectedCommands: []
        )
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 1)
        XCTAssertEqual(callUseCase.allowedUsersJoinCall, invitedParticipants)
    }
    
    @MainActor func testInviteParticipants_onCallAndWaitingRoomEnabledAndOpenInviteEnabled_shouldCallAllowUsersJoinCallAndMatchInvitedUsers() {
        let chatRoom = ChatRoomEntity(isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let invitedParticipants: [HandleEntity] = [1]
        test(
            viewModel: sut,
            action: .inviteParticipants(invitedParticipants),
            expectedCommands: []
        )
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 1)
        XCTAssertEqual(callUseCase.allowedUsersJoinCall, invitedParticipants)
    }
    
    @MainActor func testInviteParticipants_onNotCall_shouldNotCallAllowUsersJoinCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let callUseCase = MockCallUseCase(call: nil)
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            callUseCase: callUseCase
        )
        
        let invitedParticipants: [HandleEntity] = [1]
        test(
            viewModel: sut,
            action: .inviteParticipants(invitedParticipants),
            expectedCommands: []
        )
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 0)
    }
    
    @MainActor func testInviteParticipants_onWaitingRoomNotEnabled_shouldNotCallAllowUsersJoinCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: false)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            callUseCase: callUseCase
        )
        
        let invitedParticipants: [HandleEntity] = [1]
        test(
            viewModel: sut,
            action: .inviteParticipants(invitedParticipants),
            expectedCommands: []
        )
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 0)
    }
    
    @MainActor func testInviteParticipants_onNotModeratorAndNotOpenInviteEnabled_shouldNotCallAllowUsersJoinCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isOpenInviteEnabled: false, isWaitingRoomEnabled: true)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            callUseCase: callUseCase
        )
        
        let invitedParticipants: [HandleEntity] = [1]
        test(
            viewModel: sut,
            action: .inviteParticipants(invitedParticipants),
            expectedCommands: []
        )
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 0)
    }
    
    @MainActor func testInviteParticipants_onCallAndWaitingRoomEnabledAndModeratorAndCallChangeTypeWaitingRoomUsersAlowAndUsersInvitedMatch_shouldInviteUsersToCall() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, chatType: .meeting, isWaitingRoomEnabled: true)
        let call = CallEntity(status: .inProgress, chatId: 100, changeType: .waitingRoomUsersAllow, waitingRoomHandleList: [1])
        let callUseCase = MockCallUseCase(call: call)
        let chatUseCase = MockChatUseCase(activeCallEntity: call, currentChatConnectionStatus: .online)
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase
        )
        
        test(
            viewModel: sut,
            actions: [
                .inviteParticipants([1]),
                .updateContent
            ],
            expectedCommands: [
                .configNavigationBar,
                .configureStartOrJoinCallButton(sut.titleForStartOrJoinCallButton, true),
                .showTapToReturnToCall("Tap to return to call 00:00")
            ]
        )
        
        XCTAssertEqual(callUseCase.addPeer_CalledTimes, 1)
    }
    
    @MainActor func testInviteParticipants_onCallAndWaitingRoomEnabledAndModeratorAndCallChangeTypeWaitingRoomUsersAlowAndUsersInvitedNotMatch_shouldNotInviteUsersToCall() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, chatType: .meeting, isWaitingRoomEnabled: true)
        let call = CallEntity(status: .inProgress, chatId: 100, changeType: .waitingRoomUsersAllow, waitingRoomHandleList: [2])
        let callUseCase = MockCallUseCase(call: call)
        let chatUseCase = MockChatUseCase(activeCallEntity: call, currentChatConnectionStatus: .online)
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase
        )
        
        test(
            viewModel: sut,
            actions: [
                .inviteParticipants([1]),
                .updateContent
            ],
            expectedCommands: [
                .configNavigationBar,
                .configureStartOrJoinCallButton(sut.titleForStartOrJoinCallButton, true),
                .showTapToReturnToCall("Tap to return to call 00:00")
            ]
        )
        
        XCTAssertEqual(callUseCase.addPeer_CalledTimes, 0)
    }
    
    @MainActor
    func testDetermineNavBarRightItems_onIsEditing_shouldBeCancel() {
        let chatRoom = ChatRoomEntity()
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom)
        
        let result = sut.determineNavBarRightItems(isEditing: true)
        
        XCTAssertEqual(result, .cancel)
    }
    
    @MainActor
    func testDetermineNavBarRightItems_onIsNotEditingAndOneToOneChat_shouldBeVideoAndAudioCall() {
        let chatRoom = ChatRoomEntity(chatType: .oneToOne)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom)
        
        let result = sut.determineNavBarRightItems(isEditing: false)
        
        XCTAssertEqual(result, .videoAndAudioCall)
    }
    
    @MainActor
    func testDetermineNavBarRightItems_onIsNotEditingAndNotOneToOneChatAndModerator_shouldBeAddParticipantAndAudioCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isActive: true, chatType: .group)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom)
        
        let result = sut.determineNavBarRightItems(isEditing: false)
        
        XCTAssertEqual(result, .addParticipantAndAudioCall)
    }
    
    @MainActor
    func testDetermineNavBarRightItems_onIsNotEditingAndNotOneToOneChatAndOpenInviteEnabled_shouldBeAddParticipantAndAudioCall() {
        let chatRoom = ChatRoomEntity(isActive: true, chatType: .group, isOpenInviteEnabled: true)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom)
        
        let result = sut.determineNavBarRightItems(isEditing: false)
        
        XCTAssertEqual(result, .addParticipantAndAudioCall)
    }
    
    @MainActor func testDetermineNavBarRightItems_AddParticipantAndAudioCallWhenChatRoomActive_Moderator() {
        let chatRoom = ChatRoomEntity.canInviteAnd(isActive: true, canInvite: .moderator)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom)
        XCTAssertEqual(sut.determineNavBarRightItems(isEditing: false), .addParticipantAndAudioCall)
    }
    
    @MainActor func testDetermineNavBarRightItems_AddParticipantAndAudioCallWhenChatRoomActive_OpenInvite() {
        let chatRoom = ChatRoomEntity.canInviteAnd(isActive: true, canInvite: .openInvite)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom)
        XCTAssertEqual(sut.determineNavBarRightItems(isEditing: false), .addParticipantAndAudioCall)
    }
    
    @MainActor func testDetermineNavBarRightItems_NotHasAddParticipantAndAudioCallWhenChatRoomInActive_Moderator() {
        let chatRoom = ChatRoomEntity.canInviteAnd(isActive: false, canInvite: .moderator)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom)
        XCTAssertEqual(sut.determineNavBarRightItems(isEditing: false), .audioCall)
    }
    
    @MainActor func testDetermineNavBarRightItems_DoNotHasAddParticipantAndAudioCallWhenChatRoomInActive_OpenInvite() {
        let chatRoom = ChatRoomEntity.canInviteAnd(isActive: false, canInvite: .openInvite)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom)
        XCTAssertEqual(sut.determineNavBarRightItems(isEditing: false), .audioCall)
    }
    
    @MainActor
    func testDetermineNavBarRightItems_onIsNotEditingAndNotOneToOneChatAndNotModeratorAndOpenInviteNotEnabled_shouldBeAudioCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .group, isOpenInviteEnabled: false)
        let (sut, _) = makeChatContentViewModel(chatRoom: chatRoom)
        
        let result = sut.determineNavBarRightItems(isEditing: false)
        
        XCTAssertEqual(result, .audioCall)
    }
    
    @MainActor func testStartOrJoinFloatingButtonTappedTwice_startCall_startCallCalledJustOnce() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callController = MockCallController()
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil, callCompletion: .success(CallEntity())),
            callController: callController
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 1)
    }
    
    @MainActor func testStartOrJoinFloatingButtonTappedTwice_joinCallInProgress_startCallCalledJustOnce() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let call = CallEntity(status: .userNoPresent)
        let callUseCase = MockCallUseCase(call: call, answerCallCompletion: .success(call))
        let callController = MockCallController()
        let (sut, _) = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callController: callController
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callController.startCall_CalledTimes == 1)
    }
    
    // MARK: - Private
    
    @MainActor private func makeChatContentViewModel(
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatPresenceUseCase: some ChatPresenceUseCaseProtocol = MockChatPresenceUseCase(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        callUpdateUseCase: some CallUpdateUseCaseProtocol = MockCallUpdateUseCase(),
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        permissionRouter: MockPermissionAlertRouter? = nil,
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol = MockAnalyticsEventUseCase(),
        meetingNoUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol = MockMeetingNoUserJoinedUseCase(),
        handleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callController: some CallControllerProtocol = MockCallController(),
        callsManager: some CallsManagerProtocol = MockCallsManager(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> (ChatContentViewModel, MockChatContentRouter) {
        let router = MockChatContentRouter()
        
        let _permissionRouter: any PermissionAlertRouting = if let permissionRouter {
            permissionRouter
        } else {
            MockPermissionAlertRouter()
        }

        let sut = ChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatPresenceUseCase: chatPresenceUseCase,
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            audioSessionUseCase: audioSessionUseCase,
            transfersListenerUseCase: MockTransfersListenerUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            router: router,
            permissionRouter: _permissionRouter,
            analyticsEventUseCase: analyticsEventUseCase,
            meetingNoUserJoinedUseCase: meetingNoUserJoinedUseCase,
            handleUseCase: handleUseCase,
            callController: callController,
            callsManager: callsManager,
            noteToSelfNewFeatureBadgeStore: NoteToSelfNewFeatureBadgeStore(userAttributeUseCase: MockUserAttributeUseCase()),
            featureFlagProvider: featureFlagProvider
        )
        return (sut, router)
    }
}

final class MockChatContentRouter: ChatContentRouting {
    var startCallUI_calledTimes = 0
    var openWaitingRoom_calledTimes = 0
    var showCallAlreadyInProgress_calledTimes = 0
    var showEndCallDialog_calledTimes = 0
    var removeEndCallDialogIfNeeded_calledTimes = 0

    func startCallUI(chatRoom: ChatRoomEntity, call: CallEntity, isSpeakerEnabled: Bool) {
        startCallUI_calledTimes += 1
    }
    
    func openWaitingRoom(scheduledMeeting: ScheduledMeetingEntity) {
        openWaitingRoom_calledTimes += 1
    }
    
    func showCallAlreadyInProgress(endAndJoinAlertHandler: (() -> Void)?) {
        showCallAlreadyInProgress_calledTimes += 1
    }
    
    func showEndCallDialog(stayOnCallCompletion: @escaping () -> Void, endCallCompletion: @escaping () -> Void) {
        showEndCallDialog_calledTimes += 1
    }
    
    func removeEndCallDialogIfNeeded() {
        removeEndCallDialogIfNeeded_calledTimes += 1
    }
}

enum CanInviteMode {
case moderator
case openInvite
}

extension ChatRoomEntity {
    static func canInviteAnd(isActive: Bool, canInvite: CanInviteMode) -> Self {
        switch canInvite {
        case .moderator:
            ChatRoomEntity(
                ownPrivilege: .moderator, // <-
                isActive: isActive,
                chatType: .meeting,
                isOpenInviteEnabled: false
            )
        case .openInvite:
            ChatRoomEntity(
                ownPrivilege: .standard,
                isActive: isActive,
                chatType: .meeting,
                isOpenInviteEnabled: true // <-
            )
        }
    }
}
