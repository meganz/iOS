@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class WaitingRoomParticipantViewModelTests: XCTestCase {
    func testAction_admitTapped_allowUsersShouldBeCalled() {
        let callUseCase = MockCallUseCase()
        let viewModel = WaitingRoomParticipantViewModel(
            chatRoomUseCase: MockChatRoomUseCase(),
            chatRoomUserUseCase: MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Bob")),
            chatUseCase: MockChatUseCase(),
            callUseCase: callUseCase,
            waitingRoomParticipantId: 100,
            chatRoom: ChatRoomEntity(),
            call: CallEntity())
        
        viewModel.admitTapped()
        XCTAssertTrue(callUseCase.allowUsersJoinCall_CalledTimes == 1)
    }
    
    func testAction_denyTapped_kickUsersShouldBeCalled() {
        let callUseCase = MockCallUseCase()
        let viewModel = WaitingRoomParticipantViewModel(
            chatRoomUseCase: MockChatRoomUseCase(),
            chatRoomUserUseCase: MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Bob")),
            chatUseCase: MockChatUseCase(),
            callUseCase: callUseCase,
            waitingRoomParticipantId: 100,
            chatRoom: ChatRoomEntity(),
            call: CallEntity())
        
        viewModel.denyTapped()
        XCTAssertTrue(callUseCase.kickUsersFromCall_CalledTimes == 1)
    }
}

final class MockWaitingRoomParticipantsListRouter: WaitingRoomParticipantsListRouting {
    var dismiss_calledTimes = 0
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
}
