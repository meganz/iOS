@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ParticipantInWaitingRoomViewModelTests: XCTestCase {
    var admitParticipantHandler_calledTimes = 0
    var denyParticipantHandler_calledTimes = 0
    
    let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: true)
    let userImageUseCase = MockUserImageUseCase()
    let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatType: .group))
    let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
    let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
    
    @MainActor func testAction_onViewReady_shouldUpdateNameAndAvatar() {
        let sut = makeSUT()
        test(viewModel: sut,
             actions: [.onViewReady],
             expectedCommands: [
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onAdmitButtonTapped_shouldCallAdmitButtonHandler() {
        let sut = makeSUT()
        test(viewModel: sut,
             actions: [.admitButtonTapped],
             expectedCommands: [])
        XCTAssertEqual(admitParticipantHandler_calledTimes, 1)
        XCTAssertEqual(denyParticipantHandler_calledTimes, 0)
    }
    
    @MainActor func testAction_onDenyButtonTapped_shouldCallDenyButtonHandler() {
        let sut = makeSUT()
        test(viewModel: sut,
             actions: [.denyButtonTapped],
             expectedCommands: [])
        XCTAssertEqual(denyParticipantHandler_calledTimes, 1)
        XCTAssertEqual(admitParticipantHandler_calledTimes, 0)
    }
    
    @MainActor private func makeSUT() -> ParticipantInWaitingRoomViewModel {
        ParticipantInWaitingRoomViewModel(
            participant: participant,
            userImageUseCase: userImageUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            megaHandleUseCase: megaHandleUseCase,
            admitButtonEnabled: false,
            admitButtonTappedHandler: { _ in
                self.admitParticipantHandler_calledTimes += 1
            },
            denyButtonMenuTappedHandler: { _ in
                self.denyParticipantHandler_calledTimes += 1
            }
        )
    }
}
