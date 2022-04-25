import XCTest
@testable import MEGA

final class MeetingParticipantViewModelTests: XCTestCase {
    
    func testAction_onViewReady_isMe() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: true, isInContactList: false)
        let userUseCase = MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: true),
                .updateName(name: "Test (Me)"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_isOtherThanMe() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: true, isInContactList: false)
        let userUseCase = MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: false),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_isParticipant() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: false, isInContactList: false)
        let userUseCase = MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: false, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: false),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_isGuest() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: false, isInContactList: false)
        let userUseCase = MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: false, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: false),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_isMicMuted() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: true, isInContactList: false, audio: .off)
        let userUseCase = MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: true, isVideoOn: false, shouldHideContextMenu: false),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_isVideoOn() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: true, isInContactList: false, video: .on)
        let userUseCase = MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: false, isVideoOn: true, shouldHideContextMenu: false),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onContextMenuTapped() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: true, isInContactList: false, video: .on)
        let userUseCase = MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        var completionBlockCalled = false
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, userUseCase: userUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in completionBlockCalled = true }
        test(viewModel: viewModel, action: .contextMenuTapped(button: UIButton()), expectedCommands: [])
        XCTAssert(completionBlockCalled, "Context menu completion block not called")
    }
}




