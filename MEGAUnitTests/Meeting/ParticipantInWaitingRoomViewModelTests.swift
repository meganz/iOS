@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ParticipantInWaitingRoomViewModelTests: XCTestCase {
    var admitParticipantHandler_calledTimes = 0
    var denyParticipantHandler_calledTimes = 0
    
    let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: true)
    let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
    let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatType: .group))
    let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
    let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
    
    func testAction_onViewReady_shouldUpdateNameAndAvatar() {
        let sut = makeSUT()
        test(viewModel: sut,
             actions: [.onViewReady],
             expectedCommands: [
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onAdmitButtonTapped_shouldCallAdmitButtonHandler() {
        let sut = makeSUT()
        test(viewModel: sut,
             actions: [.admitButtonTapped],
             expectedCommands: [])
        XCTAssertEqual(admitParticipantHandler_calledTimes, 1)
        XCTAssertEqual(denyParticipantHandler_calledTimes, 0)
    }
    
    func testAction_onDenyButtonTapped_shouldCallDenyButtonHandler() {
        let sut = makeSUT()
        test(viewModel: sut,
             actions: [.denyButtonTapped],
             expectedCommands: [])
        XCTAssertEqual(denyParticipantHandler_calledTimes, 1)
        XCTAssertEqual(admitParticipantHandler_calledTimes, 0)
    }
    
    private func makeSUT() -> ParticipantInWaitingRoomViewModel {
        ParticipantInWaitingRoomViewModel(participant: participant,
                                          userImageUseCase: userImageUseCase,
                                          chatRoomUseCase: chatRoomUseCase,
                                          chatRoomUserUseCase: userUseCase,
                                          megaHandleUseCase: megaHandleUseCase) { _ in
            self.admitParticipantHandler_calledTimes += 1
        } denyButtonMenuTappedHandler: { _ in
            self.denyParticipantHandler_calledTimes += 1
        }
    }
}
