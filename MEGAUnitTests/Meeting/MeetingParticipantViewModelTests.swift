import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class MeetingParticipantViewModelTests: XCTestCase {
    
    func testAction_onViewReady_isMe() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: true, isInContactList: false)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"), chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, accountUseCase: accountUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
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
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"), chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, accountUseCase: accountUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
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
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"), chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, accountUseCase: accountUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
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
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"), chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, accountUseCase: accountUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
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
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"), chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, accountUseCase: accountUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
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
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"), chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, accountUseCase: accountUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
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
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"), chatRoomEntity: ChatRoomEntity())
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        var completionBlockCalled = false
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, accountUseCase: accountUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in completionBlockCalled = true }
        test(viewModel: viewModel, action: .contextMenuTapped(button: UIButton()), expectedCommands: [])
        XCTAssert(completionBlockCalled, "Context menu completion block not called")
    }
    
    func testAction_onViewReady_clearCache() {
        let particpant = CallParticipantEntity(participantId: 100)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"), chatRoomEntity: ChatRoomEntity())
        let expectation = expectation(description: "Awaiting publisher")
        let userImageUseCase = MockUserImageUseCase(clearAvatarCacheCompletion: { handle in
            XCTAssert(handle == 100, "Handle should match")
            expectation.fulfill()
        })
        let viewModel = MeetingParticipantViewModel(participant: particpant, userImageUseCase: userImageUseCase, accountUseCase: accountUseCase, chatRoomUseCase: chatRoomUseCase) { _,_ in }
        viewModel.dispatch(.onViewReady)
        userImageUseCase.avatarChangePublisher.send([100])
        waitForExpectations(timeout: 20)
    }
}
