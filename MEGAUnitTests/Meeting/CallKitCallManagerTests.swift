import CallKit
@testable import MEGA
import MEGADomain
import Testing

extension ChatRoomEntity {
    static var testEntity: ChatRoomEntity {
        ChatRoomEntity(title: "TITLE")
    }
}

extension UUID {
    static let testUUID = UUID(uuidString: "deadbeef-dead-dead-dead-deaddeafbeef")!
}

extension String {
    static let testChatIdBase64 = "base"
}

@Suite("CallKitCallManager")
struct CallKitCallManagerTests {
    class MockCallController: CallControlling {
        var requestedTransactions: [CXTransaction] = []
        var errorToReturn: (any Error)?
        func request(_ transaction: CXTransaction, completion: @escaping ((any Error)?) -> Void) {
            requestedTransactions.append(transaction)
            completion(errorToReturn)
        }
        
        func request(_ transaction: CXTransaction) async throws { /* not used */ }
        
        func requestTransaction(with actions: [CXAction], completion: @escaping ((any Error)?) -> Void) { /* not used */ }
        
        func requestTransaction(with actions: [CXAction]) async throws { /* not used */ }
        
        func requestTransaction(with action: CXAction, completion: @escaping ((any Error)?) -> Void) { /* not used */ }
        
        func requestTransaction(with action: CXAction) async throws { /* not used */ }
        
    }
    class Harness {
        let callController = MockCallController()
        let sut: CallKitCallManager
        init() {
            sut = CallKitCallManager(
                callController: callController,
                uuidFactory: { .testUUID },
                chatIdBase64Converter: { _ in .testChatIdBase64 }
            )
        }
        
        func startCall(hasVideo: Bool = true, isJoiningActiveCall: Bool = false) -> Self {
            sut.startCall(
                with: CallActionSync(
                    chatRoom: .testEntity,
                    videoEnabled: hasVideo,
                    notRinging: true,
                    isJoiningActiveCall: isJoiningActiveCall
                )
            )
            return self
        }
        func firstReceivedAction() -> CXAction? {
            callController.requestedTransactions.first?.actions.first
        }
        
        func lastReceivedAction() -> CXAction? {
            callController.requestedTransactions.last?.actions.first
        }
    }
    
    @Suite("Start call")
    struct StartCall {
        
        @Test("Start call notifies controller", arguments: [false, true])
        func startCall_isVideo_notifiesCallController(isVideo: Bool) throws {
            
            let action = Harness()
                .startCall(hasVideo: isVideo)
                .firstReceivedAction()
            let startAction = try #require(action as? CXStartCallAction)
            #expect(startAction.isVideo == isVideo)
            #expect(startAction.contactIdentifier == "TITLE")
            #expect(startAction.handle.type == .generic)
            #expect(startAction.handle.value == "base")
        }
        
        @Test("Start call and read data")
        func startCall_thenReadingCallData() throws {
            let harness = Harness().startCall()
            let callAction = try #require(harness.sut.call(forUUID: .testUUID))
            #expect(callAction.chatRoom == .testEntity)
        }
    }
    
    @Suite("Remove Call")
    struct RemoveCall {
        
        @Test("Removing call cleans storage")
        func removeCall_cleansStorage() throws {
            let harness = Harness().startCall()
            harness.sut.removeCall(withUUID: .testUUID)
            #expect(harness.sut.call(forUUID: .testUUID) == nil)
        }
        
        @Test("Removing all calls cleans storage")
        func removeAllCalls_cleansStorage() throws {
            let harness = Harness().startCall()
            harness.sut.removeAllCalls()
            #expect(harness.sut.call(forUUID: .testUUID) == nil)
        }
    }
    
    @Test
    func answerCall_notifiesCallController() throws {
        let harness = Harness()
        harness.sut.answerCall(in: .testEntity, withUUID: .testUUID)
        let action = try #require(harness.firstReceivedAction() as? CXAnswerCallAction)
        #expect(action.callUUID == .testUUID)
    }
    
    @Test
    func endCall_notifiesCallController() throws {
        let harness = Harness()
        harness.sut.startCall(
            with: CallActionSync(
                chatRoom: .testEntity
            )
        )
        harness.sut.endCall(in: .testEntity, endForAll: true)
        let action = try #require(harness.lastReceivedAction() as? CXEndCallAction)
        #expect(action.callUUID == .testUUID)
    }
    
    @Test
    func updateCall_updatesStorage() throws {
        let harness = Harness().startCall()
        harness.sut.updateCall(withUUID: .testUUID, muted: true)
        let callMuted = try #require(harness.sut.call(forUUID: .testUUID))
        #expect(callMuted.audioEnabled == false)
        harness.sut.updateCall(withUUID: .testUUID, muted: false)
        let callUnmuted = try #require(harness.sut.call(forUUID: .testUUID))
        #expect(callUnmuted.audioEnabled == true)
    }
}
