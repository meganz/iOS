import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class ActiveCallViewModelTests: XCTestCase {
    var subscription: AnyCancellable?
    
    @MainActor
    func testAction_joinCallViewTapped() {
        let router = MockChatRoomsListRouter()
        let call = CallEntity()
        let mockChatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: MockActiveCallUseCase(), chatRoomUseCase: mockChatRoomUseCase)
        viewModel.activeCallViewTapped()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssert(router.openCallView_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    func testAction_callStatusChangeAvFlags_VideoAndAudioEnabled() {
        let router = MockChatRoomsListRouter()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity(callId: 100)
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase, chatRoomUseCase: MockChatRoomUseCase())
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                expectation.fulfill()
            }
         
        activeCallUseCase.callUpdatePublisher.send(CallEntity(callId: 100, changeType: .localAVFlags, hasLocalAudio: true, hasLocalVideo: true))
        
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.video != nil && viewModel.muted == nil)
        subscription = nil
    }
    
    func testAction_callStatusChangeAvFlags_VideoAndAudioDisabled() {
        let router = MockChatRoomsListRouter()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity(callId: 100)
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase, chatRoomUseCase: MockChatRoomUseCase())
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                expectation.fulfill()
            }
         
        activeCallUseCase.callUpdatePublisher.send(CallEntity(callId: 100, changeType: .localAVFlags, hasLocalAudio: false, hasLocalVideo: false))
        
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.video == nil && viewModel.muted != nil)
        subscription = nil
    }
    
    func testAction_callStatusChangeAvFlags_VideoDisabledAndAudioEnabled() {
        let router = MockChatRoomsListRouter()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity(callId: 100)
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase, chatRoomUseCase: MockChatRoomUseCase())
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                expectation.fulfill()
            }
         
        activeCallUseCase.callUpdatePublisher.send(CallEntity(callId: 100, changeType: .localAVFlags, hasLocalAudio: true, hasLocalVideo: false))
        
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.video == nil && viewModel.muted == nil)
        subscription = nil
    }
    
    func testAction_callStatusChangeAvFlags_VideoEnabledAndAudioDisabled() {
        let router = MockChatRoomsListRouter()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity(callId: 100)
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase, chatRoomUseCase: MockChatRoomUseCase())
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                expectation.fulfill()
            }
         
        activeCallUseCase.callUpdatePublisher.send(CallEntity(callId: 100, changeType: .localAVFlags, hasLocalAudio: false, hasLocalVideo: true))
        
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.video != nil && viewModel.muted != nil)
        subscription = nil
    }
    
    func testAction_callStatusReconnecting() {
        let router = MockChatRoomsListRouter()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity()
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase, chatRoomUseCase: MockChatRoomUseCase())
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                expectation.fulfill()
            }

        activeCallUseCase.callUpdatePublisher.send(CallEntity(status: .connecting))
            
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.message == Strings.Localizable.reconnecting)
        subscription = nil
    }
    
    func testAction_callStatusInProgress() {
        let router = MockChatRoomsListRouter()
        let activeCallUseCase = MockActiveCallUseCase()
        let call = CallEntity()
        let viewModel = ActiveCallViewModel(call: call, router: router, activeCallUseCase: activeCallUseCase, chatRoomUseCase: MockChatRoomUseCase())
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = activeCallUseCase
            .callUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                expectation.fulfill()
            }

        activeCallUseCase.callUpdatePublisher.send(CallEntity(status: .inProgress))
            
        waitForExpectations(timeout: 10)
        XCTAssert(viewModel.message != Strings.Localizable.reconnecting)
        subscription = nil
    }
}
