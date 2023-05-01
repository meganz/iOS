import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class ChatContentViewModelTests: XCTestCase {
    
    func testAction_startOrJoinCallCleanUp_callCleanUp() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.startOrJoinCallCleanUp(false),
             expectedCommands: [ChatContentViewModel.Command.startOrJoinCallCleanUp(false, [])])
    }
    
    func testAction_updateCallNavigationBarButtons_callUpdateCallBarButtons() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateCallNavigationBarButtons(false, false, true, false),
             expectedCommands: [ChatContentViewModel.Command.enableAudioVideoButtons(false)])
    }
    
    func testAction_startMeetingNoRinging_callStartMeetingNoRinging() {
        let chatRoom = MockChatRoom(ownPrivilage: .standard).toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.startMeetingNoRinging(false, false, false, true, false),
             expectedCommands: [ChatContentViewModel.Command.startMeetingNoRinging(false, ScheduledMeetingEntity())])
    }
    
    func testAction_startOutGoingCall_callStartOutGoingCall() {
        let chatRoom = MockChatRoom(ownPrivilage: .standard).toChatRoomEntity()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.startOutGoingCall(false, false, false, true, false),
             expectedCommands: [ChatContentViewModel.Command.startOutGoingCall(false)])
    }
    
    func testUpdateContentIfNeeded_callIsNil_shouldCallCleanUpAndUpdateStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.currentChatConnectionStatus = .online
        
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateContent,
             expectedCommands: [ChatContentViewModel.Command.tapToReturnToCallCleanUp, ChatContentViewModel.Command.startOrJoinCallCleanUp(false, [])])
    }
    
    func testUpdateContentIfNeeded_connectionIsNotOnline_shouldCallCleanUpAndUpdateStartOrJoinCallButton() {
        let chatRoom = MockChatRoom().toChatRoomEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase()
        let chatUseCase = MockChatUseCase()
        chatUseCase.activeCallEntity = CallEntity()
        chatUseCase.currentChatConnectionStatus = .invalid
        
        let sut = ChatContentViewModel(chatRoom: chatRoom, chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        test(viewModel: sut, action: ChatContentAction.updateContent,
             expectedCommands: [ChatContentViewModel.Command.tapToReturnToCallCleanUp, ChatContentViewModel.Command.startOrJoinCallCleanUp(false, [])])
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
                                ChatContentViewModel.Command.startOrJoinCallCleanUp(false, []),
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
                                ChatContentViewModel.Command.startOrJoinCallCleanUp(false, []),
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
                                ChatContentViewModel.Command.startOrJoinCallCleanUp(false, []),
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
}
