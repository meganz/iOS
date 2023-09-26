@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class MainTabBarCallsViewModelTests: XCTestCase {
    private let router = MockMainTabBarCallsRouter()
    private var viewModel: MainTabBarCallsViewModel!
    private let chatUseCase = MockChatUseCase()
    private let callUseCase = MockCallUseCase()

    func testCallUpdate_onCallUpdateInProgressAndBeingModerator_waitingRoomListenerExists() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase()
        
        viewModel = MainTabBarCallsViewModel(router: router,
                                             chatUseCase: chatUseCase,
                                             callUseCase: callUseCase,
                                             chatRoomUseCase: chatRoomUseCase,
                                             chatRoomUserUseCase: userUseCase)
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress))

        evaluate {
            self.viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
    }
    
    func testCallUpdate_onCallUpdateInProgressAndNotBeingModerator_waitingRoomListenerNotExists() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase()
        
        viewModel = MainTabBarCallsViewModel(router: router,
                                             chatUseCase: chatUseCase,
                                             callUseCase: callUseCase,
                                             chatRoomUseCase: chatRoomUseCase,
                                             chatRoomUserUseCase: userUseCase)
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress))

        evaluate {
            self.viewModel.callWaitingRoomUsersUpdateSubscription == nil
        }
    }
    
    func testCallUpdate_onCallUpdateInProgressAndWaitingRoomNotEnabled_waitingRoomListenerNotExists() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: false), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase()
        
        viewModel = MainTabBarCallsViewModel(router: router,
                                             chatUseCase: chatUseCase,
                                             callUseCase: callUseCase,
                                             chatRoomUseCase: chatRoomUseCase,
                                             chatRoomUserUseCase: userUseCase)
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress))

        evaluate {
            self.viewModel.callWaitingRoomUsersUpdateSubscription == nil
        }
    }
    
    func testCallUpdate_oneUserOnWaitingRoomAndBeingModerator_showOneUserAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))

        viewModel = MainTabBarCallsViewModel(router: router,
                                             chatUseCase: chatUseCase,
                                             callUseCase: callUseCase,
                                             chatRoomUseCase: chatRoomUseCase,
                                             chatRoomUserUseCase: userUseCase)
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress))
        
        evaluate {
            self.viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(waitingRoom: WaitingRoomEntity(sessionClientIds: [100])))

        evaluate {
            self.router.showOneUserWaitingRoomDialog_calledTimes == 1
        }
    }
    
    func testCallUpdate_severalUsersOnWaitingAndRoomBeingModerator_showSeveralUsersAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase()

        viewModel = MainTabBarCallsViewModel(router: router,
                                             chatUseCase: chatUseCase,
                                             callUseCase: callUseCase,
                                             chatRoomUseCase: chatRoomUseCase,
                                             chatRoomUserUseCase: userUseCase)
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress))
        
        evaluate {
            self.viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(waitingRoom: WaitingRoomEntity(sessionClientIds: [100, 101])))

        evaluate {
            self.router.showSeveralUsersWaitingRoomDialog_calledTimes == 1
        }
    }
    
    func testCallUpdate_noUsersOnWaitingRoomAndBeingModerator_dismissAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase()

        viewModel = MainTabBarCallsViewModel(router: router,
                                             chatUseCase: chatUseCase,
                                             callUseCase: callUseCase,
                                             chatRoomUseCase: chatRoomUseCase,
                                             chatRoomUserUseCase: userUseCase)
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress))
        
        evaluate {
            self.viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(waitingRoom: WaitingRoomEntity(sessionClientIds: [])))

        evaluate {
            self.router.dismissWaitingRoomDialog_calledTimes == 1
        }
    }
    
    // MARK: - Private methods
    
    private func evaluate(expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 5)
    }
}

final class MockMainTabBarCallsRouter: MainTabBarCallsRouting {
    
    var showOneUserWaitingRoomDialog_calledTimes = 0
    var showSeveralUsersWaitingRoomDialog_calledTimes = 0
    var dismissWaitingRoomDialog_calledTimes = 0
    var showConfirmDenyAction_calledTimes = 0
    var showParticipantsJoinedTheCall_calledTimes = 0
    var showWaitingRoomListFor_calledTimes = 0
    
    func showOneUserWaitingRoomDialog(for username: String, chatName: String, isCallUIVisible: Bool, admitAction: @escaping () -> Void, denyAction: @escaping () -> Void) {
        showOneUserWaitingRoomDialog_calledTimes += 1
    }
    
    func showSeveralUsersWaitingRoomDialog(for participantsCount: Int, chatName: String, isCallUIVisible: Bool, admitAction: @escaping () -> Void, seeWaitingRoomAction: @escaping () -> Void) {
        showSeveralUsersWaitingRoomDialog_calledTimes += 1
    }
    
    func dismissWaitingRoomDialog(animated: Bool) {
        dismissWaitingRoomDialog_calledTimes += 1
    }

    func showConfirmDenyAction(for username: String, isCallUIVisible: Bool, confirmDenyAction: @escaping () -> Void, cancelDenyAction: @escaping () -> Void) {
        showConfirmDenyAction_calledTimes += 1
    }
    
    func showParticipantsJoinedTheCall(message: String) {
        showParticipantsJoinedTheCall_calledTimes += 1
    }
    
    func showWaitingRoomListFor(call: CallEntity, in chatRoom: ChatRoomEntity) {
        showWaitingRoomListFor_calledTimes += 1
    }
}
