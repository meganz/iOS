import CallKit
@testable import MEGA
import MEGADomain
import Testing
import TestingExpectation

@Suite("CallKitProviderDelegate")
struct CallKitProviderDelegateTests {
    class MockStartAction: CXStartCallAction {
        
        init(callUUID: UUID) {
            super.init(call: callUUID, handle: .init(type: .generic, value: ""))
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var fulfillCalled = Expectation()
        override func fulfill() {
            fulfillCalled.fulfill()
        }
        
        var failCalled = Expectation()
        override func fail() {
            failCalled.fulfill()
        }
    }
    class MockAnswerAction: CXAnswerCallAction {
        
        init(callUUID: UUID) {
            super.init(call: callUUID)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var fulfillCalled = Expectation()
        override func fulfill() {
            fulfillCalled.fulfill()
        }
        
        var failCalled = Expectation()
        override func fail() {
            failCalled.fulfill()
        }
    }
    class MockEndAction: CXEndCallAction {
        
        init(callUUID: UUID) {
            super.init(call: callUUID)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var fulfillCalled = Expectation()
        override func fulfill() {
            fulfillCalled.fulfill()
        }
        
        var failCalled = Expectation()
        override func fail() {
            failCalled.fulfill()
        }
    }
    class MockMutedAction: CXSetMutedCallAction {

        var fulfillCalled: TestingExpectation.Expectation!
        override func fulfill() {
            fulfillCalled.fulfill()
        }
        
        var failCalled: TestingExpectation.Expectation!
        override func fail() {
            failCalled.fulfill()
        }
    }
    
    class Harness {
        let callsManager = MockCallsManager()
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
                callsManager: callsManager,
                cxProviderFactory: {
                    cxProvider
                },
                callUpdateFactory: CXCallUpdateFactory(builder: { CXCallUpdate() })
            )
            
            if setupCallManager {
                callsManager.callForUUIDToReturn = .init(chatRoom: ChatRoomEntity())
            }
        }
    }
    
    @Test("Reset provider removes all calls from callManager")
    func didReset_informesCallManager() {
        let harness = Harness()
        harness.sut.providerDidReset(harness.cxProvider)
        #expect(harness.callsManager.removeAllCalls_CalledTimes == 1)
    }
    
    @Suite("Start Call")
    struct StartCall {
        @Test("Perform Start call action succeeds")
        func startCall_Succeeds() async {
            let harness = Harness()
            harness.callCoordinator.startCallResult_ToReturn = true
            let startAction = MockStartAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: startAction)
            await harness.callCoordinator.startCallCalled.fulfillment(within: .seconds(5))
            await startAction.fulfillCalled.fulfillment(within: .seconds(5))
            #expect(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes == 1)
        }
        @Test("Perform Start call action fails")
        func startCall_Fails() async {
            let harness = Harness()
            harness.callCoordinator.startCallResult_ToReturn = false
            let startAction = MockStartAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: startAction)
            await harness.callCoordinator.startCallCalled.fulfillment(within: .seconds(5))
            await startAction.failCalled.fulfillment(within: .seconds(5))
            #expect(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes == 0)
        }
    }
    
    @Suite("Answer Call")
    struct AnswerCall {
        @Test("Performs answer call action, succeeds")
        func answerAction_succeeds() async {
            let harness = Harness()
            harness.callsManager.callForUUIDToReturn = .init(chatRoom: ChatRoomEntity())
            harness.callCoordinator.answerCallResult_ToReturn = true
            let answerAction = MockAnswerAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: answerAction)
            await harness.callCoordinator.answerCallCalled.fulfillment(within: .seconds(5))
            await answerAction.fulfillCalled.fulfillment(within: .seconds(5))
            #expect(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes == 1)
            
        }
        @Test("Performs answer call action, fails")
        func answerAction_fails() async {
            let harness = Harness()
            harness.callCoordinator.answerCallResult_ToReturn = false
            let answerAction = MockAnswerAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: answerAction)
            await harness.callCoordinator.answerCallCalled.fulfillment(within: .seconds(5))
            await answerAction.failCalled.fulfillment(within: .seconds(5))
            #expect(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes == 0)
        }
    }
    @Suite("End Call")
    struct EndCall {
        @Test("Perform end call action, succeed")
        func endCall_succeeded() async {
            let harness = Harness()
            harness.callCoordinator.endCallResult_ToReturn = true
            let endAction = MockEndAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: endAction)
            await harness.callCoordinator.endCallCalled.fulfillment(within: .seconds(5))
            await endAction.fulfillCalled.fulfillment(within: .seconds(5))
            #expect(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes == 0)
        }
        
        @Test("Perform end call action, fails")
        func endCall_failed() async {
            let harness = Harness()
            harness.callCoordinator.endCallResult_ToReturn = false
            let endAction = MockEndAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: endAction)
            await harness.callCoordinator.endCallCalled.fulfillment(within: .seconds(5))
            await endAction.failCalled.fulfillment(within: .seconds(5))
            #expect(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes == 0)
        }
    }
    @Suite("Mute call")
    struct MuteCall {
        @Test("Perform mute action succeeds")
        func muteCall_succeeded() async {
            let harness = Harness()
            harness.callCoordinator.muteCallResult_ToReturn = true
            let muteAction = MockMutedAction(call: .init(), muted: true)
            muteAction.fulfillCalled = Expectation()
            harness.sut.provider(harness.cxProvider, perform: muteAction)
            await harness.callCoordinator.muteCallCalled.fulfillment(within: .seconds(5))
            await muteAction.fulfillCalled.fulfillment(within: .seconds(5))
            #expect(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes == 0)
        }
        @Test("Perform mute action fails")
        func muteCall_failed() async {
            let harness = Harness()
            harness.callCoordinator.muteCallResult_ToReturn = false
            let muteAction = MockMutedAction(call: .init(), muted: true)
            muteAction.failCalled = Expectation()
            harness.sut.provider(harness.cxProvider, perform: muteAction)
            await harness.callCoordinator.muteCallCalled.fulfillment(within: .seconds(5))
            await muteAction.failCalled.fulfillment(within: .seconds(5))
            #expect(harness.callCoordinator.disablePassCodeIfNeeded_CalledTimes == 0)
        }
    }
}
