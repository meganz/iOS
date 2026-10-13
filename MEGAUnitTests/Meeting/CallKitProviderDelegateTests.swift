import CallKit
@testable import MEGA
import MEGADomain
import Testing

@MainActor
@Suite("CallKitProviderDelegate", .timeLimit(.minutes(1)))
struct CallKitProviderDelegateTests {
    enum ActionResult {
        case fulfilled
        case failed
    }

    /// Records whether the delegate fulfilled or failed an action.
    /// The delegate decides in a new Task, so a test awaits the result and never relies on a deadline.
    final class ActionResultRecorder: Sendable {
        private let results: AsyncStream<ActionResult>
        private let continuation: AsyncStream<ActionResult>.Continuation

        init() {
            (results, continuation) = AsyncStream.makeStream(of: ActionResult.self)
        }

        func record(_ result: ActionResult) {
            continuation.yield(result)
        }

        /// Returns the first recorded result. The stream is buffered, so an earlier result still counts.
        func firstResult() async -> ActionResult? {
            for await result in results {
                return result
            }
            return nil
        }
    }

    class MockStartAction: CXStartCallAction {
        let recorder = ActionResultRecorder()

        init(callUUID: UUID) {
            super.init(call: callUUID, handle: .init(type: .generic, value: ""))
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func fulfill() {
            recorder.record(.fulfilled)
        }

        override func fail() {
            recorder.record(.failed)
        }
    }

    final class MockAnswerAction: CXAnswerCallAction {
        let recorder = ActionResultRecorder()

        init(callUUID: UUID) {
            super.init(call: callUUID)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func fulfill() {
            recorder.record(.fulfilled)
        }

        override func fail() {
            recorder.record(.failed)
        }
    }
    class MockEndAction: CXEndCallAction {
        let recorder = ActionResultRecorder()

        init(callUUID: UUID) {
            super.init(call: callUUID)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func fulfill() {
            recorder.record(.fulfilled)
        }

        override func fail() {
            recorder.record(.failed)
        }
    }
    class MockMutedAction: CXSetMutedCallAction {
        // The inherited Objective-C init skips Swift property defaults, so a test sets this after init.
        var recorder: ActionResultRecorder!

        override func fulfill() {
            recorder.record(.fulfilled)
        }

        override func fail() {
            recorder.record(.failed)
        }
    }
    
    @MainActor
    final class Harness {
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
    
    @MainActor
    @Suite("Start Call")
    struct StartCall {
        @Test("Perform Start call action succeeds")
        func startCall_Succeeds() async {
            let harness = Harness()
            harness.callCoordinator.startCallResult_ToReturn = true
            let startAction = MockStartAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: startAction)
            #expect(await startAction.recorder.firstResult() == .fulfilled)
            #expect(harness.callCoordinator.startCall_CalledTimes == 1)
        }
        @Test("Perform Start call action fails")
        func startCall_Fails() async {
            let harness = Harness()
            harness.callCoordinator.startCallResult_ToReturn = false
            let startAction = MockStartAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: startAction)
            #expect(await startAction.recorder.firstResult() == .failed)
            #expect(harness.callCoordinator.startCall_CalledTimes == 1)
        }
    }
    
    @MainActor
    @Suite("Answer Call")
    struct AnswerCall {
        @Test("Performs answer call action, succeeds")
        func answerAction_succeeds() async {
            let harness = Harness()
            harness.callsManager.callForUUIDToReturn = .init(chatRoom: ChatRoomEntity())
            harness.callCoordinator.answerCallResult_ToReturn = true
            let answerAction = MockAnswerAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: answerAction)
            #expect(await answerAction.recorder.firstResult() == .fulfilled)
            #expect(harness.callCoordinator.answerCall_CalledTimes == 1)
        }
        @Test("Performs answer call action, fails")
        func answerAction_fails() async {
            let harness = Harness()
            harness.callCoordinator.answerCallResult_ToReturn = false
            let answerAction = MockAnswerAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: answerAction)
            #expect(await answerAction.recorder.firstResult() == .failed)
            #expect(harness.callCoordinator.answerCall_CalledTimes == 1)
        }
    }
    
    @MainActor
    @Suite("End Call")
    struct EndCall {
        @Test("Perform end call action, succeed")
        func endCall_succeeded() async {
            let harness = Harness()
            harness.callCoordinator.endCallResult_ToReturn = true
            let endAction = MockEndAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: endAction)
            #expect(await endAction.recorder.firstResult() == .fulfilled)
            #expect(harness.callCoordinator.endCall_CalledTimes == 1)
        }
        
        @Test("Perform end call action, fails")
        func endCall_failed() async {
            let harness = Harness()
            harness.callCoordinator.endCallResult_ToReturn = false
            let endAction = MockEndAction(callUUID: .init())
            harness.sut.provider(harness.cxProvider, perform: endAction)
            #expect(await endAction.recorder.firstResult() == .failed)
            #expect(harness.callCoordinator.endCall_CalledTimes == 1)
        }
    }
    
    @MainActor
    @Suite("Mute call")
    struct MuteCall {
        @Test("Perform mute action succeeds")
        func muteCall_succeeded() async {
            let harness = Harness()
            harness.callCoordinator.muteCallResult_ToReturn = true
            let muteAction = MockMutedAction(call: .init(), muted: true)
            muteAction.recorder = ActionResultRecorder()
            harness.sut.provider(harness.cxProvider, perform: muteAction)
            #expect(await muteAction.recorder.firstResult() == .fulfilled)
            #expect(harness.callCoordinator.muteCall_CalledTimes == 1)
        }
        @Test("Perform mute action fails")
        func muteCall_failed() async {
            let harness = Harness()
            harness.callCoordinator.muteCallResult_ToReturn = false
            let muteAction = MockMutedAction(call: .init(), muted: true)
            muteAction.recorder = ActionResultRecorder()
            harness.sut.provider(harness.cxProvider, perform: muteAction)
            #expect(await muteAction.recorder.firstResult() == .failed)
            #expect(harness.callCoordinator.muteCall_CalledTimes == 1)
        }
    }
    
    @MainActor
    @Suite("Audio Session")
    struct AudioSessionTests {
        @Test("Provider did activate audio session calls coordinator and configures WebRTC")
        func providerDidActivate_callsCoordinator() async {
            let harness = Harness()
            harness.sut.provider(harness.cxProvider, didActivate: AVAudioSession.sharedInstance())
            #expect(harness.callCoordinator.didActivateCallAudioSession_CalledTimes == 1)
        }
        
        @Test("Provider did deactivate audio session calls coordinator")
        func providerDidDeactivate_callsCoordinator() async {
            let harness = Harness()
            harness.sut.provider(harness.cxProvider, didDeactivate: AVAudioSession.sharedInstance())
            #expect(harness.callCoordinator.didDeactivateCallAudioSession_CalledTimes == 1)
        }
    }
}
