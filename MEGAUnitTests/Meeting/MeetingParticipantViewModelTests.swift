@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class MeetingParticipantViewModelTests: XCTestCase {
    
    @MainActor func testAction_onViewReady_isMe() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: true)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let viewModel = MeetingParticipantViewModel(participant: particpant,
                                                    userImageUseCase: userImageUseCase,
                                                    accountUseCase: accountUseCase,
                                                    chatRoomUseCase: chatRoomUseCase,
                                                    chatRoomUserUseCase: userUseCase,
                                                    megaHandleUseCase: megaHandleUseCase) { _, _ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: true, raisedHand: false),
                .updateName(name: "Test (Me)"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_isOtherThanMe() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: true)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(101))
        let viewModel = MeetingParticipantViewModel(participant: particpant,
                                                    userImageUseCase: userImageUseCase,
                                                    accountUseCase: accountUseCase,
                                                    chatRoomUseCase: chatRoomUseCase,
                                                    chatRoomUserUseCase: userUseCase,
                                                    megaHandleUseCase: megaHandleUseCase) { _, _ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: false, raisedHand: false),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_isParticipant() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: false)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(101))
        let viewModel = MeetingParticipantViewModel(participant: particpant,
                                                    userImageUseCase: userImageUseCase,
                                                    accountUseCase: accountUseCase,
                                                    chatRoomUseCase: chatRoomUseCase,
                                                    chatRoomUserUseCase: userUseCase,
                                                    megaHandleUseCase: megaHandleUseCase) { _, _ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: false, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: false, raisedHand: false),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_isGuest() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: false)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(101))
        let viewModel = MeetingParticipantViewModel(participant: particpant,
                                                    userImageUseCase: userImageUseCase,
                                                    accountUseCase: accountUseCase,
                                                    chatRoomUseCase: chatRoomUseCase,
                                                    chatRoomUserUseCase: userUseCase,
                                                    megaHandleUseCase: megaHandleUseCase) { _, _ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: false, isMicMuted: false, isVideoOn: false, shouldHideContextMenu: false, raisedHand: false),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_isMicMuted() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: true, audio: .off)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(101))
        let viewModel = MeetingParticipantViewModel(participant: particpant,
                                                    userImageUseCase: userImageUseCase,
                                                    accountUseCase: accountUseCase,
                                                    chatRoomUseCase: chatRoomUseCase,
                                                    chatRoomUserUseCase: userUseCase,
                                                    megaHandleUseCase: megaHandleUseCase) { _, _ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: true, isVideoOn: false, shouldHideContextMenu: false, raisedHand: false),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_isVideoOn() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: true, video: .on)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(101))
        let viewModel = MeetingParticipantViewModel(participant: particpant,
                                                    userImageUseCase: userImageUseCase,
                                                    accountUseCase: accountUseCase,
                                                    chatRoomUseCase: chatRoomUseCase,
                                                    chatRoomUserUseCase: userUseCase,
                                                    megaHandleUseCase: megaHandleUseCase) { _, _ in }
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(isModerator: true, isMicMuted: false, isVideoOn: true, shouldHideContextMenu: false, raisedHand: false),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onContextMenuTapped() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: true, video: .on)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        var completionBlockCalled = false
        let viewModel = MeetingParticipantViewModel(participant: particpant,
                                                    userImageUseCase: userImageUseCase,
                                                    accountUseCase: accountUseCase,
                                                    chatRoomUseCase: chatRoomUseCase,
                                                    chatRoomUserUseCase: userUseCase,
                                                    megaHandleUseCase: MockMEGAHandleUseCase()) { _, _ in completionBlockCalled = true }
        test(viewModel: viewModel, action: .contextMenuTapped(button: UIButton()), expectedCommands: [])
        XCTAssert(completionBlockCalled, "Context menu completion block not called")
    }
    
    @MainActor
    func testAction_onViewReady_clearCache() async {
        let particpant = CallParticipantEntity(participantId: 100)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let expectation = expectation(description: "Awaiting publisher")
        let userImageUseCase = MockUserImageUseCase(clearAvatarCacheCompletion: { handle in
            XCTAssert(handle == "100", "Handle should match")
            expectation.fulfill()
        })
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let viewModel = MeetingParticipantViewModel(participant: particpant,
                                                    userImageUseCase: userImageUseCase,
                                                    accountUseCase: accountUseCase,
                                                    chatRoomUseCase: chatRoomUseCase,
                                                    chatRoomUserUseCase: userUseCase,
                                                    megaHandleUseCase: megaHandleUseCase) { _, _ in }
        viewModel.dispatch(.onViewReady)
        await viewModel.loadNameTask?.value
        userImageUseCase.avatarChangePublisher.send([100])
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
