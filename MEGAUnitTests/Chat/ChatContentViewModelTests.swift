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
    
    func testStartOrJoinCallCleanUp_callCleanUp() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .startOrJoinCallCleanUp,
             expectedCommands: [.hideStartOrJoinCallButton(true)])
    }
    
    func testUpdateCallNavigationBarButtons_callUpdateCallBarButtons() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateCallNavigationBarButtons(false, false),
             expectedCommands: [.enableAudioVideoButtons(false)])
    }
    
    func testStartCallBarButtonTapped_audioCall_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil, callCompletion: .success(CallEntity())),
            callManager: callManager
        )
        
        test(viewModel: sut, action: .startCallBarButtonTapped(isVideoEnabled: false),
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 1)
    }
    
    func testStartCallBarButtonTapped_audioCallNoAudioGranted_dontShowCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil),
            permissionRouter: MockPermissionAlertRouter(isAudioPermissionGranted: false),
            callManager: callManager
        )
        
        test(viewModel: sut, action: .startCallBarButtonTapped(isVideoEnabled: false),
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 0)
    }
    
    func testStartCallBarButtonTapped_videoCall_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil, callCompletion: .success(CallEntity())),
            callManager: callManager
        )
        
        test(viewModel: sut, action: .startCallBarButtonTapped(isVideoEnabled: true),
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 1)
    }
    
    func testStartCallBarButtonTapped_videoCallNoVideoGranted_dontShowCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil),
            permissionRouter: MockPermissionAlertRouter(isVideoPermissionGranted: false),
            callManager: callManager
        )
        
        test(viewModel: sut, action: .startCallBarButtonTapped(isVideoEnabled: true),
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 0)
    }
    
    func testStartOrJoinFloatingButtonTapped_existsOtherCallInProgres_showCallAlreadyInProgress() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(isExistingActiveCall: true, currentChatConnectionStatus: .online)
        let callUseCase = MockCallUseCase(call: CallEntity(status: .userNoPresent))
        let router = MockChatContentRouter()
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            router: router,
            callManager: callManager
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 0)
        XCTAssert(router.showCallAlreadyInProgress_calledTimes == 1)
    }
    
    func testStartOrJoinFloatingButtonTapped_startCall_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil, callCompletion: .success(CallEntity())),
            callManager: callManager
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 1)
    }
    
    func testStartOrJoinFloatingButtonTapped_answerRingingCall_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let call = CallEntity(isRinging: true)
        let callUseCase = MockCallUseCase(call: call, answerCallCompletion: .success(call))
        let callManager = MockCallManager()
        callManager.addIncomingCall(withUUID: UUID(), chatRoom: chatRoom)
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callManager: callManager
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callManager.answerCall_CalledTimes == 1)
    }
    
    func testReturnToCallBannerButtonTapped_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let router = MockChatContentRouter()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            router: router
        )

        test(viewModel: sut, action: .returnToCallBannerButtonTapped,
             expectedCommands: [])
        XCTAssert(router.startCallUI_calledTimes == 1)
    }
    
    func testReturnToCallBannerButtonTapped_WaitingRoomEnabledUserStandard_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let router = MockChatContentRouter()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            router: router
        )

        test(viewModel: sut, action: .returnToCallBannerButtonTapped,
             expectedCommands: [])
        XCTAssert(router.startCallUI_calledTimes == 1)
    }
    
    func testReturnToCallBannerButtonTapped_WaitingRoomEnabledUserModerator_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let router = MockChatContentRouter()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            router: router
        )

        test(viewModel: sut, action: .returnToCallBannerButtonTapped,
             expectedCommands: [])
        XCTAssert(router.startCallUI_calledTimes == 1)
    }
    
    func testStartOrJoinFloatingButtonTapped_startCall_openWaitingRoom() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let router = MockChatContentRouter()
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil),
            scheduledMeetingUseCase: MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()]),
            router: router,
            callManager: callManager
        )

        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 0)
        XCTAssert(router.openWaitingRoom_calledTimes == 1)
    }
    
    func testStartOrJoinFloatingButtonTapped_startCallWaitingRoomEnabledUserModerator_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: MockCallUseCase(call: nil, callCompletion: .success(CallEntity())),
            callManager: callManager
        )

        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 1)
    }
    
    func testStartOrJoinFloatingButtonTapped_joinCallInProgress_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let call = CallEntity(status: .userNoPresent)
        let callUseCase = MockCallUseCase(call: call, answerCallCompletion: .success(call))
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callManager: callManager
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 1)
    }
    
    func testStartOrJoinFloatingButtonTapped_joinCallInProgressWaitingRoomEnabledUserModerator_showCallUI() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let call = CallEntity(status: .userNoPresent)
        let callUseCase = MockCallUseCase(call: call, answerCallCompletion: .success(call))
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callManager: callManager
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 1)
    }
    
    func testStartOrJoinFloatingButtonTapped_joinCallInProgressWaitingRoomEnabledUserStandard_openWaitingRoom() {
        let router = MockChatContentRouter()
        let callManager = MockCallManager()
        let sut = makeChatContentViewModel(
            chatRoom: ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true),
            chatUseCase: MockChatUseCase(currentChatConnectionStatus: .online),
            callUseCase: MockCallUseCase(call: CallEntity(status: .userNoPresent)),
            scheduledMeetingUseCase: MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()]),
            router: router,
            callManager: callManager
        )
        
        test(viewModel: sut, action: .startOrJoinFloatingButtonTapped,
             expectedCommands: [])
        XCTAssert(callManager.startCall_CalledTimes == 0)
        XCTAssert(router.openWaitingRoom_calledTimes == 1)
    }
    
    func testUpdateContent_callIsNil_shouldCallCleanUpAndUpdateStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase
        )
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.tapToReturnToCallCleanUp, .hideStartOrJoinCallButton(true)])
    }
    
    func testUpdateContent_connectionIsNotOnline_shouldCallCleanUpAndUpdateStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.activeCallEntity = CallEntity()
        chatUseCase.currentChatConnectionStatus = .invalid
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.tapToReturnToCallCleanUp, .hideStartOrJoinCallButton(true)])
    }
    
    func testUpdateContent_joiningTheCall_shouldCall4Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.activeCallEntity = CallEntity(status: .joining, chatId: chatRoom.chatId)
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.configNavigationBar,
                                .hideStartOrJoinCallButton(true),
                                .tapToReturnToCallCleanUp,
                                .showStartOrJoinCallButton
                               ])
    }
    
    func testUpdateContent_callInProgress_shouldCall2Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        let callEntity = CallEntity(status: .inProgress, chatId: chatRoom.chatId)
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.configNavigationBar,
                                .hideStartOrJoinCallButton(true),
                                .showTapToReturnToCall("Tap to return to call 00:00")
                               ])
    }
    
    func testUpdateContent_callInProgressLastPeerLeavesAndUserIsTheOnlyOneInTheCall_shouldShowEndCallDialog() {
        let router = MockChatContentRouter()
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase(myUserHandle: 100)
        let callEntity = CallEntity(status: .inProgress, chatId: chatRoom.chatId, changeType: .callComposition, numberOfParticipants: 1, participants: [chatUseCase.myUserHandle()])
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            router: router
        )
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.configNavigationBar,
                                .hideStartOrJoinCallButton(true),
                                .showTapToReturnToCall("Tap to return to call 00:00")
                               ])
        XCTAssert(router.showEndCallDialog_calledTimes == 1)
    }
    
    func testUpdateContent_callInConnecting_shouldCall2Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        let callEntity = CallEntity(status: .connecting, chatId: chatRoom.chatId)
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.configNavigationBar,
                                .showTapToReturnToCall(Strings.Localizable.reconnecting)
                               ])
    }
    
    func testUpdateContent_callInDestroyed_shouldCall3Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        let callEntity = CallEntity(status: .destroyed, chatId: chatRoom.chatId)
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: .updateContent,
             expectedCommands: [.configNavigationBar,
                                .hideStartOrJoinCallButton(true),
                                .tapToReturnToCallCleanUp])
    }
    
    func testUpdateCallNavigationBarButtons_forWaitingRoomNonHost_shouldNotEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
        test(
            viewModel: sut,
            action: .updateCallNavigationBarButtons(false, false),
            expectedCommands: [
                .enableAudioVideoButtons(false)
            ]
        )
    }
    
    func testUpdateCallNavigationBarButtons_forWaitingRoomHost_shouldEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
        test(
            viewModel: sut,
            action: .updateCallNavigationBarButtons(false, false),
            expectedCommands: [
                .enableAudioVideoButtons(true)
            ]
        )
    }
    
    func testUpdateCallNavigationBarButtons_onPrivilegeChangeFromModeratorToStandard_shouldNotEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
        let newChatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        test(
            viewModel: sut,
            actions: [
                .updateChatRoom(newChatRoom),
                .updateCallNavigationBarButtons(false, false)
            ],
            expectedCommands: [
                .enableAudioVideoButtons(false)
            ]
        )
    }
    
    func testUpdateCallNavigationBarButtons_onPrivilegeChangeFromStandardToModerator_shouldEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
        let newChatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        test(
            viewModel: sut,
            actions: [
                .updateChatRoom(newChatRoom),
                .updateCallNavigationBarButtons(false, false)
            ],
            expectedCommands: [
                .enableAudioVideoButtons(true)
            ]
        )
    }
    
    func testInviteParticipants_onCallAndWaitingRoomEnabledAndModerator_shouldCallAllowUsersJoinCallAndMatchInvitedUsers() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let sut = makeChatContentViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let invitedParticipants: [HandleEntity] = [1]
        test(
            viewModel: sut,
            action: .inviteParticipants(invitedParticipants),
            expectedCommands: []
        )
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 1)
        XCTAssertEqual(callUseCase.allowedUsersJoinCall, invitedParticipants)
    }
    
    func testInviteParticipants_onCallAndWaitingRoomEnabledAndOpenInviteEnabled_shouldCallAllowUsersJoinCallAndMatchInvitedUsers() {
        let chatRoom = ChatRoomEntity(isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let sut = makeChatContentViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let invitedParticipants: [HandleEntity] = [1]
        test(
            viewModel: sut,
            action: .inviteParticipants(invitedParticipants),
            expectedCommands: []
        )
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 1)
        XCTAssertEqual(callUseCase.allowedUsersJoinCall, invitedParticipants)
    }
    
    func testInviteParticipants_onNotCall_shouldNotCallAllowUsersJoinCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let callUseCase = MockCallUseCase(call: nil)
        let sut = makeChatContentViewModel(
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
    
    func testInviteParticipants_onWaitingRoomNotEnabled_shouldNotCallAllowUsersJoinCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: false)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let sut = makeChatContentViewModel(
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
    
    func testInviteParticipants_onNotModeratorAndNotOpenInviteEnabled_shouldNotCallAllowUsersJoinCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isOpenInviteEnabled: false, isWaitingRoomEnabled: true)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let sut = makeChatContentViewModel(
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
    
    func testInviteParticipants_onCallAndWaitingRoomEnabledAndModeratorAndCallChangeTypeWaitingRoomUsersAlowAndUsersInvitedMatch_shouldInviteUsersToCall() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, chatType: .meeting, isWaitingRoomEnabled: true)
        let call = CallEntity(status: .inProgress, chatId: 100, changeType: .waitingRoomUsersAllow, waitingRoomHandleList: [1])
        let callUseCase = MockCallUseCase(call: call)
        let chatUseCase = MockChatUseCase(activeCallEntity: call, currentChatConnectionStatus: .online)
        let sut = makeChatContentViewModel(
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
                .hideStartOrJoinCallButton(true),
                .showTapToReturnToCall("Tap to return to call 00:00")
            ]
        )
        
        XCTAssertEqual(callUseCase.addPeer_CalledTimes, 1)
    }
    
    func testInviteParticipants_onCallAndWaitingRoomEnabledAndModeratorAndCallChangeTypeWaitingRoomUsersAlowAndUsersInvitedNotMatch_shouldNotInviteUsersToCall() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, chatType: .meeting, isWaitingRoomEnabled: true)
        let call = CallEntity(status: .inProgress, chatId: 100, changeType: .waitingRoomUsersAllow, waitingRoomHandleList: [2])
        let callUseCase = MockCallUseCase(call: call)
        let chatUseCase = MockChatUseCase(activeCallEntity: call, currentChatConnectionStatus: .online)
        let sut = makeChatContentViewModel(
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
                .hideStartOrJoinCallButton(true),
                .showTapToReturnToCall("Tap to return to call 00:00")
            ]
        )
        
        XCTAssertEqual(callUseCase.addPeer_CalledTimes, 0)
    }
    
    func testDetermineNavBarRightItems_onIsEditing_shouldBeCancel() {
        let chatRoom = ChatRoomEntity()
        let sut = makeChatContentViewModel(chatRoom: chatRoom)
        
        let result = sut.determineNavBarRightItems(isEditing: true)
        
        XCTAssertEqual(result, .cancel)
    }
    
    func testDetermineNavBarRightItems_onIsNotEditingAndOneToOneChat_shouldBeVideoAndAudioCall() {
        let chatRoom = ChatRoomEntity(chatType: .oneToOne)
        let sut = makeChatContentViewModel(chatRoom: chatRoom)
        
        let result = sut.determineNavBarRightItems(isEditing: false)
        
        XCTAssertEqual(result, .videoAndAudioCall)
    }
    
    func testDetermineNavBarRightItems_onIsNotEditingAndNotOneToOneChatAndModerator_shouldBeAddParticipantAndAudioCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .group)
        let sut = makeChatContentViewModel(chatRoom: chatRoom)
        
        let result = sut.determineNavBarRightItems(isEditing: false)
        
        XCTAssertEqual(result, .addParticipantAndAudioCall)
    }
    
    func testDetermineNavBarRightItems_onIsNotEditingAndNotOneToOneChatAndOpenInviteEnabled_shouldBeAddParticipantAndAudioCall() {
        let chatRoom = ChatRoomEntity(chatType: .group, isOpenInviteEnabled: true)
        let sut = makeChatContentViewModel(chatRoom: chatRoom)
        
        let result = sut.determineNavBarRightItems(isEditing: false)
        
        XCTAssertEqual(result, .addParticipantAndAudioCall)
    }
    
    func testDetermineNavBarRightItems_onIsNotEditingAndNotOneToOneChatAndNotModeratorAndOpenInviteNotEnabled_shouldBeAudioCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .group, isOpenInviteEnabled: false)
        let sut = makeChatContentViewModel(chatRoom: chatRoom)
        
        let result = sut.determineNavBarRightItems(isEditing: false)
        
        XCTAssertEqual(result, .audioCall)
    }
    
    // MARK: - Private
    
    private func makeChatContentViewModel(
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        router: some ChatContentRouting = MockChatContentRouter(),
        permissionRouter: some PermissionAlertRouting = MockPermissionAlertRouter(),
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol = MockAnalyticsEventUseCase(),
        meetingNoUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol = MockMeetingNoUserJoinedUseCase(),
        handleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callManager: some CallManagerProtocol = MockCallManager(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> ChatContentViewModel {
        let sut = ChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            chatRoomUseCase: chatRoomUseCase,
            callUseCase: callUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            audioSessionUseCase: audioSessionUseCase,
            router: router,
            permissionRouter: permissionRouter,
            analyticsEventUseCase: analyticsEventUseCase,
            meetingNoUserJoinedUseCase: meetingNoUserJoinedUseCase,
            handleUseCase: handleUseCase, 
            callManager: callManager,
            featureFlagProvider: featureFlagProvider
        )
        return sut
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
