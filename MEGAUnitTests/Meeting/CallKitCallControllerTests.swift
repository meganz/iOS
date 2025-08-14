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

@Suite("CallKitCallController")
struct CallKitCallControllerTests {
    class MockCallKitCallController: CXCallController {
        var requestedTransactions: [CXTransaction] = []
        var errorToReturn: (any Error)?
        override func request(_ transaction: CXTransaction, completion: @escaping ((any Error)?) -> Void) {
            requestedTransactions.append(transaction)
            completion(errorToReturn)
        }
    }
    class Harness {
        let callController = MockCallKitCallController()
        let callsManager = MockCallsManager()
        let sut: CallKitCallController
        init() {
            sut = CallKitCallController(
                callController: callController,
                uuidFactory: { .testUUID },
                chatIdBase64Converter: { _ in .testChatIdBase64 },
                callsManager: callsManager,
                callKitProviderDelegateFactory: MockCallKitProviderDelegateFactory()
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
}
