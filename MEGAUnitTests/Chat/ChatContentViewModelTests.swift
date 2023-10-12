import ChatRepoMock
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class ChatContentViewModelTests: XCTestCase {
    
    func testAction_startOrJoinCallCleanUp_callCleanUp() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.startOrJoinCallCleanUp,
             expectedCommands: [ChatContentViewModel.Command.hideStartOrJoinCallButton(true)])
    }
    
    func testAction_updateCallNavigationBarButtons_callUpdateCallBarButtons() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateCallNavigationBarButtons(false, false, true),
             expectedCommands: [ChatContentViewModel.Command.enableAudioVideoButtons(false)])
    }
    
    func testAction_startMeetingNoRinging_callStartMeetingNoRinging() {
        let chatRoom = MockChatRoom(ownPrivilage: .standard).toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.startMeetingNoRinging(false, false, false, true),
             expectedCommands: [ChatContentViewModel.Command.startMeetingNoRinging(false, ScheduledMeetingEntity())])
    }
    
    func testAction_startOutGoingCall_callStartOutGoingCall() {
        let chatRoom = MockChatRoom(ownPrivilage: .standard).toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.startOutGoingCall(false, false, false, true),
             expectedCommands: [ChatContentViewModel.Command.startOutGoingCall(false)])
    }
    
    func testUpdateContentIfNeeded_callIsNil_shouldCallCleanUpAndUpdateStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateContent,
             expectedCommands: [ChatContentViewModel.Command.tapToReturnToCallCleanUp, ChatContentViewModel.Command.hideStartOrJoinCallButton(true)])
    }
    
    func testUpdateContentIfNeeded_connectionIsNotOnline_shouldCallCleanUpAndUpdateStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.activeCallEntity = CallEntity()
        chatUseCase.currentChatConnectionStatus = .invalid
        
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateContent,
             expectedCommands: [ChatContentViewModel.Command.tapToReturnToCallCleanUp, ChatContentViewModel.Command.hideStartOrJoinCallButton(true)])
    }
    
    func testUpdateContentIfNeeded_joiningTheCall_shouldCall4Commands() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.activeCallEntity = CallEntity(status: .joining, chatId: chatRoom.chatId)
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
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
        
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
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
        
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
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
        
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
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
        
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateCall(callEntity),
             expectedCommands: [ChatContentViewModel.Command.configNavigationBar,
                                ChatContentViewModel.Command.showTapToReturnToCall(Strings.Localizable.reconnecting)
                               ])
    }
    
    func testUpdateCallNavigationBarButtons_forWaitingRoomNonHost_shouldNotEnableAudioVideoButtons() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
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
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
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
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
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
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase)
        
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
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
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
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
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
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
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
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(
            viewModel: sut,
            action: ChatContentAction.startMeetingNoRinging(true, false, false, true),
            expectedCommands: [
                ChatContentViewModel.Command.startMeetingNoRinging(true, ScheduledMeetingEntity())
            ]
        )
    }
    
    func testShouldOpenWaitingRoom_onNotModeratorAndWaitingRoomEnabledAndNotReturnToCall_shouldReturnTrue() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let sut = ChatContentViewModel(chatRoom: chatRoom)
        
        XCTAssertTrue(sut.shouldOpenWaitingRoom(isReturnToCall: false))
    }
    
    func testShouldOpenWaitingRoom_onNotModeratorAndWaitingRoomEnabledAndReturnToCall_shouldReturnFalse() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let sut = ChatContentViewModel(chatRoom: chatRoom)
        
        XCTAssertFalse(sut.shouldOpenWaitingRoom(isReturnToCall: true))
    }
}
