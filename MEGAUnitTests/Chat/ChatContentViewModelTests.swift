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
    
    func testAction_startOrJoinCallCleanUp_callCleanUp() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.startOrJoinCallCleanUp,
             expectedCommands: [ChatContentViewModel.Command.hideStartOrJoinCallButton(true)])
    }
    
    func testAction_updateCallNavigationBarButtons_callUpdateCallBarButtons() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateCallNavigationBarButtons(false, false, true),
             expectedCommands: [ChatContentViewModel.Command.enableAudioVideoButtons(false)])
    }
    
    func testAction_startMeetingNoRinging_callStartMeetingNoRinging() {
        let chatRoom = MockChatRoom(ownPrivilage: .standard).toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.startMeetingNoRinging(false, false, false, true),
             expectedCommands: [ChatContentViewModel.Command.startMeetingNoRinging(false, ScheduledMeetingEntity())])
    }
    
    func testAction_startOutGoingCall_callStartOutGoingCall() {
        let chatRoom = MockChatRoom(ownPrivilage: .standard).toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase
        )
        
        test(viewModel: sut, action: ChatContentAction.startOutGoingCall(false, false, false, true),
             expectedCommands: [ChatContentViewModel.Command.startOutGoingCall(false)])
    }
    
    func testUpdateContentIfNeeded_callIsNil_shouldCallCleanUpAndUpdateStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase
        )
        
        test(viewModel: sut, action: ChatContentAction.updateContent,
             expectedCommands: [ChatContentViewModel.Command.tapToReturnToCallCleanUp, ChatContentViewModel.Command.hideStartOrJoinCallButton(true)])
    }
    
    func testUpdateContentIfNeeded_connectionIsNotOnline_shouldCallCleanUpAndUpdateStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.activeCallEntity = CallEntity()
        chatUseCase.currentChatConnectionStatus = .invalid
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateContent,
             expectedCommands: [ChatContentViewModel.Command.tapToReturnToCallCleanUp, ChatContentViewModel.Command.hideStartOrJoinCallButton(true)])
    }
    
    func testUpdateContentIfNeeded_joiningTheCall_shouldCall4Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.activeCallEntity = CallEntity(status: .joining, chatId: chatRoom.chatId)
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateContent,
             expectedCommands: [ChatContentViewModel.Command.configNavigationBar,
                                ChatContentViewModel.Command.hideStartOrJoinCallButton(true),
                                ChatContentViewModel.Command.tapToReturnToCallCleanUp,
                                ChatContentViewModel.Command.showStartOrJoinCallButton
                               ])
    }
    
    func testUpdateContentIfNeeded_callInProgress_shouldCall4Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        let callEntity = CallEntity(status: .inProgress, chatId: chatRoom.chatId)
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateContent,
             expectedCommands: [ChatContentViewModel.Command.configNavigationBar,
                                ChatContentViewModel.Command.hideStartOrJoinCallButton(true),
                                ChatContentViewModel.Command.initTimerForCall(callEntity),
                                ChatContentViewModel.Command.showCallEndTimerIfNeeded(callEntity)
                               ])
    }
    
    func testUpdateContentIfNeeded_callInConnecting_shouldCall2Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        let callEntity = CallEntity(status: .connecting, chatId: chatRoom.chatId)
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateContent,
             expectedCommands: [ChatContentViewModel.Command.configNavigationBar,
                                ChatContentViewModel.Command.showTapToReturnToCall(Strings.Localizable.reconnecting)
                               ])
    }
    
    func testUpdateContentIfNeeded_callInDestroyed_shouldCall3Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        let callEntity = CallEntity(status: .destroyed, chatId: chatRoom.chatId)
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateContent,
             expectedCommands: [ChatContentViewModel.Command.configNavigationBar,
                                ChatContentViewModel.Command.hideStartOrJoinCallButton(true),
                                ChatContentViewModel.Command.tapToReturnToCallCleanUp])
    }
    
    func testUpdateCall_callInConnecting_shouldCall2Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        let callEntity = CallEntity(status: .connecting, chatId: chatRoom.chatId)
        chatUseCase.activeCallEntity = callEntity
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateCall(callEntity),
             expectedCommands: [ChatContentViewModel.Command.configNavigationBar,
                                ChatContentViewModel.Command.showTapToReturnToCall(Strings.Localizable.reconnecting)
                               ])
    }
    
    func testUpdateCallNavigationBarButtons_forWaitingRoomNonHost_shouldNotEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
        test(
            viewModel: sut,
            action: ChatContentAction.updateCallNavigationBarButtons(false, false, true),
            expectedCommands: [
                ChatContentViewModel.Command.enableAudioVideoButtons(false)
            ]
        )
    }
    
    func testUpdateCallNavigationBarButtons_forWaitingRoomHost_shouldEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
        test(
            viewModel: sut,
            action: ChatContentAction.updateCallNavigationBarButtons(false, false, true),
            expectedCommands: [
                ChatContentViewModel.Command.enableAudioVideoButtons(true)
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
                ChatContentAction.updateChatRoom(newChatRoom),
                ChatContentAction.updateCallNavigationBarButtons(false, false, true)
            ],
            expectedCommands: [
                ChatContentViewModel.Command.enableAudioVideoButtons(false)
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
                ChatContentAction.updateChatRoom(newChatRoom),
                ChatContentAction.updateCallNavigationBarButtons(false, false, true)
            ],
            expectedCommands: [
                ChatContentViewModel.Command.enableAudioVideoButtons(true)
            ]
        )
    }
    
    func testStartOutGoingCall_onWaitingRoomEnabled_shouldCallStartMeetingInWaitingRoomChat() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(
            viewModel: sut,
            action: ChatContentAction.startOutGoingCall(true, false, false, true),
            expectedCommands: [
                ChatContentViewModel.Command.startMeetingInWaitingRoomChat(true, ScheduledMeetingEntity())
            ]
        )
    }
    
    func testStartOutGoingCall_onWaitingRoomNotEnabled_shouldCallStartMeetingInWaitingRoomChat() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: false)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(
            viewModel: sut,
            action: ChatContentAction.startOutGoingCall(true, false, false, true),
            expectedCommands: [
                ChatContentViewModel.Command.startOutGoingCall(true)
            ]
        )
    }
    
    func testStartMeetingNoRinging_onWaitingRoomEnabled_shouldCallStartMeetingInWaitingRoomChatNoRinging() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(
            viewModel: sut,
            action: ChatContentAction.startMeetingNoRinging(true, false, false, true),
            expectedCommands: [
                ChatContentViewModel.Command.startMeetingInWaitingRoomChatNoRinging(true, ScheduledMeetingEntity())
            ]
        )
    }
    
    func testStartMeetingNoRinging_onWaitingRoomNotEnabled_shouldCallStartMeetingNoRinging() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: false)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let sut = makeChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(
            viewModel: sut,
            action: ChatContentAction.startMeetingNoRinging(true, false, false, true),
            expectedCommands: [
                ChatContentViewModel.Command.startMeetingNoRinging(true, ScheduledMeetingEntity())
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
            action: ChatContentAction.inviteParticipants(invitedParticipants),
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
            action: ChatContentAction.inviteParticipants(invitedParticipants),
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
            action: ChatContentAction.inviteParticipants(invitedParticipants),
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
            action: ChatContentAction.inviteParticipants(invitedParticipants),
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
            action: ChatContentAction.inviteParticipants(invitedParticipants),
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
                ChatContentAction.inviteParticipants([1]),
                ChatContentAction.updateContent
            ],
            expectedCommands: [
                .configNavigationBar,
                .hideStartOrJoinCallButton(true),
                .initTimerForCall(call),
                .showCallEndTimerIfNeeded(call)
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
                ChatContentAction.inviteParticipants([1]),
                ChatContentAction.updateContent
            ],
            expectedCommands: [
                .configNavigationBar,
                .hideStartOrJoinCallButton(true),
                .initTimerForCall(call),
                .showCallEndTimerIfNeeded(call)
            ]
        )
        
        XCTAssertEqual(callUseCase.addPeer_CalledTimes, 0)
    }
    
    func testShouldOpenWaitingRoom_onNotModeratorAndWaitingRoomEnabledAndNotReturnToCall_shouldReturnTrue() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let sut = makeChatContentViewModel(chatRoom: chatRoom)
        
        XCTAssertTrue(sut.shouldOpenWaitingRoom(isReturnToCall: false))
    }
    
    func testShouldOpenWaitingRoom_onNotModeratorAndWaitingRoomEnabledAndReturnToCall_shouldReturnFalse() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let sut = makeChatContentViewModel(chatRoom: chatRoom)
        
        XCTAssertFalse(sut.shouldOpenWaitingRoom(isReturnToCall: true))
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
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        file: StaticString = #file,
        line: UInt = #line
    ) -> ChatContentViewModel {
        let sut = ChatContentViewModel(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            chatRoomUseCase: chatRoomUseCase,
            callUseCase: callUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            featureFlagProvider: featureFlagProvider
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
