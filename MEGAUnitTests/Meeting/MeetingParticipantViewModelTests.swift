import XCTest
@testable import MEGA

final class MeetingParticipantViewModelTests: XCTestCase {
    
    func testAction_onViewReady_isAttendeeMe() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: nil, attendeeType: .moderator, isInContactList: false)
        let userUseCase = MockUserUseCase(handle: 100)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(attendee: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero) ,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: true),
                .updateName(name: "Test", isMe: true),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_isAttendeeOtherThanMe() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, networkQuality: 1, email: nil, attendeeType: .moderator, isInContactList: false)
        let userUseCase = MockUserUseCase(handle: 100)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(attendee: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero) ,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: false),
                .updateName(name: "Test", isMe: false),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_isAttendeeParticipant() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, networkQuality: 1, email: nil, attendeeType: .particpant, isInContactList: false)
        let userUseCase = MockUserUseCase(handle: 100)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(attendee: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero) ,
             expectedCommands: [
                .configView(isModerator: false, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: false),
                .updateName(name: "Test", isMe: false),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_isAttendeeGuest() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, networkQuality: 1, email: nil, attendeeType: .guest, isInContactList: false)
        let userUseCase = MockUserUseCase(handle: 100)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(attendee: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero) ,
             expectedCommands: [
                .configView(isModerator: false, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: true),
                .updateName(name: "Test", isMe: false),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_isMicMuted() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, networkQuality: 1, email: nil, attendeeType: .moderator, isInContactList: false, audio: .off)
        let userUseCase = MockUserUseCase(handle: 100)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(attendee: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero) ,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: true, isVideoOn: false, shouldHideContextMenu: false),
                .updateName(name: "Test", isMe: false),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_isVideoOn() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, networkQuality: 1, email: nil, attendeeType: .moderator, isInContactList: false, video: .on)
        let userUseCase = MockUserUseCase(handle: 100)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(attendee: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero) ,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: false, isVideoOn: true, shouldHideContextMenu: false),
                .updateName(name: "Test", isMe: false),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onContextMenuTapped() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, networkQuality: 1, email: nil, attendeeType: .moderator, isInContactList: false, video: .on)
        let userUseCase = MockUserUseCase(handle: 100)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        var completionBlockCalled = false
        let viewModel = MeetingParticipantViewModel(attendee: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in completionBlockCalled = true }
        test(viewModel: viewModel, action: .contextMenuTapped(button: UIButton()), expectedCommands: [])
        XCTAssert(completionBlockCalled, "Context menu completion block not called")
    }
}




