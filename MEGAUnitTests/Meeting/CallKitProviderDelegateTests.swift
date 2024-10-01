import CallKit
import ConcurrencyExtras
@testable import MEGA
import MEGADomain
import XCTest

final class CallKitProviderDelegateTests: XCTestCase {
    class MockStartAction: CXStartCallAction {
        
        init(callUUID: UUID) {
            super.init(call: callUUID, handle: .init(type: .generic, value: ""))
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var fulfillCalled = false
        override func fulfill() {
            fulfillCalled = true
        }
        
        var failCalled = false
        override func fail() {
            failCalled = true
        }
    }
    class MockAnswerAction: CXAnswerCallAction {
        
        init(callUUID: UUID) {
            super.init(call: callUUID)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var fulfillCalled = false
        override func fulfill() {
            fulfillCalled = true
        }
        
        var failCalled = false
        override func fail() {
            failCalled = true
        }
    }
    class MockEndAction: CXEndCallAction {
        
        init(callUUID: UUID) {
            super.init(call: callUUID)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var fulfillCalled = false
        override func fulfill() {
            fulfillCalled = true
        }
        
        var failCalled = false
        override func fail() {
            failCalled = true
        }
    }
    class MockMutedAction: CXSetMutedCallAction {
        var fulfillCalled = false
        override func fulfill() {
            fulfillCalled = true
        }
        
        var failCalled = false
        override func fail() {
            failCalled = true
        }
    }
    
    class Harness {
        let callManager = MockCallManager()
        let cxProvider: MockCXProvider
        let callCoordinator: MockCallsCoordinator
        let sut: CallKitProviderDelegate
        init(setupCallManager: Bool = true,
             callCoordinator: MockCallsCoordinator? = nil
        ) {
            let cxProvider = MockCXProvider(configuration: .init())
            self.callCoordinator = callCoordinator ?? MockCallsCoordinator()
            self.cxProvider = cxProvider
            sut = CallKitProviderDelegate(
                callCoordinator: self.callCoordinator,
                callManager: callManager,
                cxProviderFactory: {
                    cxProvider
                }
            )
            
            if setupCallManager {
                callManager.callForUUIDToReturn = .init(chatRoom: ChatRoomEntity())
            }
        }
    }
    
    func test_DidReset_informesCallManager() {
        let harness = Harness()
        harness.sut.providerDidReset(harness.cxProvider)
        XCTAssertEqual(harness.callManager.removeAllCalls_CalledTimes, 1)
    }
    
    @MainActor
    func test_performStartAction_callCoordinatorSucceeds_callStartCallInManager() async {
        await withMainSerialExecutor {
            let harness = Harness()
            harness.callCoordinator.startCallResult_ToReturn = true
            let startAction = MockStartAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: startAction)
            await Task.megaYield()
            XCTAssertEqual(harness.callCoordinator.startCall_CalledTimes, 1)
            XCTAssertEqual(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes, 1)
            XCTAssertTrue(startAction.fulfillCalled)
        }
    }
    
    func test_performStartAction_callCoordinatorFaild_callStartCallInManager() async {
        await withMainSerialExecutor {
            let harness = Harness()
            harness.callCoordinator.startCallResult_ToReturn = false
            let startAction = MockStartAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: startAction)
            await Task.megaYield()
            XCTAssertEqual(harness.callCoordinator.startCall_CalledTimes, 1)
            XCTAssertEqual(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes, 0)
            XCTAssertTrue(startAction.failCalled)
        }
    }
    
    func test_performAnswerAction_succeeded_callCoordinatorCalled() async {
        await withMainSerialExecutor {
            let harness = Harness()
            harness.callManager.callForUUIDToReturn = .init(chatRoom: ChatRoomEntity())
            harness.callCoordinator.answerCallResult_ToReturn = true
            let answerAction = MockAnswerAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: answerAction)
            await Task.megaYield()
            XCTAssertEqual(harness.callCoordinator.answerCall_CalledTimes, 1)
            XCTAssertEqual(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes, 1)
            XCTAssertTrue(answerAction.fulfillCalled)
        }
    }
    
    func test_performAnswerAction_failed_callCoordinatorCalled() async {
        await withMainSerialExecutor {
            let harness = Harness()
            harness.callCoordinator.answerCallResult_ToReturn = false
            let answerAction = MockAnswerAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: answerAction)
            await Task.megaYield()
            XCTAssertEqual(harness.callCoordinator.answerCall_CalledTimes, 1)
            XCTAssertEqual(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes, 0)
            XCTAssertTrue(answerAction.failCalled)
        }
    }
    
    func test_performEndAction_succeeded_callCoordinatorCalled() async {
        await withMainSerialExecutor {
            let harness = Harness()
            harness.callCoordinator.endCallResult_ToReturn = true
            let endAction = MockEndAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: endAction)
            await Task.megaYield()
            XCTAssertEqual(harness.callCoordinator.endCall_CalledTimes, 1)
            XCTAssertEqual(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes, 0)
            XCTAssertTrue(endAction.fulfillCalled)
        }
    }
    
    func test_performEndAction_failed_callCoordinatorCalled() async {
        await withMainSerialExecutor {
            let harness = Harness()
            harness.callCoordinator.endCallResult_ToReturn = false
            let endAction = MockEndAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: endAction)
            await Task.megaYield()
            XCTAssertEqual(harness.callCoordinator.endCall_CalledTimes, 1)
            XCTAssertEqual(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes, 0)
            XCTAssertTrue(endAction.failCalled)
        }
    }
    
    func test_performMuteAction_succeeded_callCoordinatorCalled() async {
        await withMainSerialExecutor {
            let harness = Harness()
            harness.callCoordinator.muteCallResult_ToReturn = true
            let muteAction = MockMutedAction(call: .init(), muted: true)
            harness.sut.provider(harness.cxProvider, perform: muteAction)
            await Task.megaYield()
            XCTAssertEqual(harness.callCoordinator.muteCall_CalledTimes, 1)
            XCTAssertEqual(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes, 0)
            XCTAssertTrue(muteAction.fulfillCalled)
        }
    }
    
    func test_performMuteAction_failed_callCoordinatorCalled() async {
        await withMainSerialExecutor {
            let harness = Harness()
            harness.callCoordinator.muteCallResult_ToReturn = false
            let muteAction = MockMutedAction(call: .init(), muted: true)
            harness.sut.provider(harness.cxProvider, perform: muteAction)
            await Task.megaYield()
            XCTAssertEqual(harness.callCoordinator.muteCall_CalledTimes, 1)
            XCTAssertEqual(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes, 0)
            XCTAssertTrue(muteAction.failCalled)
        }
    }
}
