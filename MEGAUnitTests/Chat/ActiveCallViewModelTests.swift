import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock
import Combine

final class ActiveCallViewModelTests: XCTestCase {
    var subscription: AnyCancellable?
    
    func testAction_joinCallViewTapped() {
        let router = MockChatRoomsListRouting()
        let call = CallEntity()
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: MockActiveCallUseCase())
        viewModel.activeCallViewTapped()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut{
            XCTAssert(router.joinActiveCall_calledTimes == 1)
        } else {
            XCTFail()
        }
    }
    
    func testAction_callStatusChangeAvFlags_VideoAndAudioEnabled() {
        let router = MockChatRoomsListRouting()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity(callId: 100)
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase)
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink(){ _ in
                expectation.fulfill()
            }
         
        activeCallUseCase.callUpdatePublisher.send(CallEntity(callId: 100, changeType: .localAVFlags, hasLocalAudio: true, hasLocalVideo: true))
        
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.video != nil && viewModel.muted == nil)
        subscription = nil
    }
    
    func testAction_callStatusChangeAvFlags_VideoAndAudioDisabled() {
        let router = MockChatRoomsListRouting()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity(callId: 100)
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase)
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink(){ _ in
                expectation.fulfill()
            }
         
        activeCallUseCase.callUpdatePublisher.send(CallEntity(callId: 100, changeType: .localAVFlags, hasLocalAudio: false, hasLocalVideo: false))
        
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.video == nil && viewModel.muted != nil)
        subscription = nil
    }
    
    func testAction_callStatusChangeAvFlags_VideoDisabledAndAudioEnabled() {
        let router = MockChatRoomsListRouting()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity(callId: 100)
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase)
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink(){ _ in
                expectation.fulfill()
            }
         
        activeCallUseCase.callUpdatePublisher.send(CallEntity(callId: 100, changeType: .localAVFlags, hasLocalAudio: true, hasLocalVideo: false))
        
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.video == nil && viewModel.muted == nil)
        subscription = nil
    }
    
    func testAction_callStatusChangeAvFlags_VideoEnabledAndAudioDisabled() {
        let router = MockChatRoomsListRouting()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity(callId: 100)
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase)
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink(){ _ in
                expectation.fulfill()
            }
         
        activeCallUseCase.callUpdatePublisher.send(CallEntity(callId: 100, changeType: .localAVFlags, hasLocalAudio: false, hasLocalVideo: true))
        
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.video != nil && viewModel.muted != nil)
        subscription = nil
    }
    
    func testAction_callStatusReconnecting() {
        let router = MockChatRoomsListRouting()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity()
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase)
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink(){ _ in
                expectation.fulfill()
            }

        activeCallUseCase.callUpdatePublisher.send(CallEntity(status: .connecting))
            
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.message == Strings.Localizable.reconnecting)
        subscription = nil
    }
    
    func testAction_callStatusInProgress() {
        let router = MockChatRoomsListRouting()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity()
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase)
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink(){ _ in
                expectation.fulfill()
            }

        activeCallUseCase.callUpdatePublisher.send(CallEntity(status: .inProgress))
            
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.message != Strings.Localizable.reconnecting)
        subscription = nil
    }
}

final class MockChatRoomsListRouting: ChatRoomsListRouting {
    
    var joinActiveCall_calledTimes = 0
    var presentStartConversation_calledTimes = 0
    var presentMeetingAlreayExists_calledTimes = 0
    var presentCreateMeeting_calledTimes = 0
    var presentEnterMeeting_calledTimes = 0
    var presentScheduleMeetingScreen_calledTimes = 0
    var showInviteContactScreen_calledTimes = 0
    var showContactsOnMegaScreen_calledTimes = 0
    var showDetails_calledTimes = 0
    var present_calledTimes = 0
    var presentMoreOptionsForChat_calledTimes = 0
    var showGroupChatInfo_calledTimes = 0
    var showContactDetailsInfo_calledTimes = 0
    var showArchivedChatRooms_calledTimes = 0
    
    var navigationController: UINavigationController?
    
    func presentStartConversation() {
        presentStartConversation_calledTimes += 1
    }
    
    func presentMeetingAlreayExists() {
        presentMeetingAlreayExists_calledTimes += 1
    }
    
    func presentCreateMeeting() {
        presentCreateMeeting_calledTimes += 1
    }
    
    func presentEnterMeeting() {
        presentEnterMeeting_calledTimes += 1
    }
    
    func presentScheduleMeetingScreen() {
        presentScheduleMeetingScreen_calledTimes += 1
    }
    
    func showInviteContactScreen() {
        showInviteContactScreen_calledTimes += 1
    }
    
    func showContactsOnMegaScreen() {
        showContactsOnMegaScreen_calledTimes += 1
    }
    
    func showDetails(forChatId chatId: MEGADomain.HandleEntity) {
        showDetails_calledTimes += 1
    }
    
    func present(alert: UIAlertController, animated: Bool) {
        present_calledTimes += 1
    }
    
    func presentMoreOptionsForChat(withDNDEnabled dndEnabled: Bool, dndAction: @escaping () -> Void, markAsReadAction: (() -> Void)?, infoAction: @escaping () -> Void, archiveAction: @escaping () -> Void) {
        presentMoreOptionsForChat_calledTimes += 1
    }
    
    func showGroupChatInfo(forChatId chatId: MEGADomain.HandleEntity) {
        showGroupChatInfo_calledTimes += 1
    }
    
    func showContactDetailsInfo(forUseHandle userHandle: MEGADomain.HandleEntity, userEmail: String) {
        showContactDetailsInfo_calledTimes += 1
    }
    
    func showArchivedChatRooms() {
        showArchivedChatRooms_calledTimes += 1
    }
    
    func joinActiveCall(_ call: MEGADomain.CallEntity) {
        joinActiveCall_calledTimes += 1
    }
}
