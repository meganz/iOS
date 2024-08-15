@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ParticipantNotInCallViewModelTests: XCTestCase {
    @MainActor func testAction_onViewReady_participantNotInCall() {
        let participant = CallParticipantEntity(participantId: 100, absentParticipantState: .notInCall)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), userStatusEntity: .online)

        let viewModel = makeParticipantNotInCallViewModel(
            participant: participant,
            chatRoomUseCase: chatRoomUseCase)
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(
                    participant.absentParticipantState.toParticipantNotInCallState(),
                    chatRoomUseCase.userStatusEntity
                )
             ]
        )
    }
    
    @MainActor func testAction_onCallButtonTapped_handlerShouldBeCalled() {
        var callButtonTapped = false
        let viewModel = makeParticipantNotInCallViewModel(callButtonTappedHandler: { _ in
            callButtonTapped = true
        })
        
        test(viewModel: viewModel, action: .onCallButtonTapped, expectedCommands: [])
        XCTAssert(callButtonTapped, "Call button tapped not called")
    }
    
    @MainActor func testAction_onViewReady_updateNameAndAvatar() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 101, clientId: 100, isModerator: false)
        let accountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatType: .group))
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(101))
        let viewModel = makeParticipantNotInCallViewModel(
            participant: participant,
            userImageUseCase: userImageUseCase,
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            userUseCase: userUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(
                    participant.absentParticipantState.toParticipantNotInCallState(),
                    chatRoomUseCase.userStatusEntity
                ),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    // MARK: - Private
    
    private func makeParticipantNotInCallViewModel(
        participant: CallParticipantEntity = CallParticipantEntity(),
        userImageUseCase: MockUserImageUseCase = MockUserImageUseCase(),
        accountUseCase: MockAccountUseCase = MockAccountUseCase(),
        chatRoomUseCase: MockChatRoomUseCase = MockChatRoomUseCase(),
        userUseCase: MockChatRoomUserUseCase = MockChatRoomUserUseCase(),
        megaHandleUseCase: MockMEGAHandleUseCase = MockMEGAHandleUseCase(),
        chatUseCase: MockChatUseCase = MockChatUseCase(),
        callButtonTappedHandler: @escaping (CallParticipantEntity) -> Void = { _ in }
    ) -> ParticipantNotInCallViewModel {
        ParticipantNotInCallViewModel(
            participant: participant,
            userImageUseCase: userImageUseCase,
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            megaHandleUseCase: megaHandleUseCase,
            chatUseCase: chatUseCase,
            callButtonTappedHandler: callButtonTappedHandler
        )
    }
}
