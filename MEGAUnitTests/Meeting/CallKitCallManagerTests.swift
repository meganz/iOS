import CallKit
import ConcurrencyExtras
@testable import MEGA
import MEGADomain
import XCTest

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

final class CallKitCallManagerTests: XCTestCase {
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
    
    func test_StartCall_isVideo_true_notifiesCallController() throws {
        let isVideo = true
        let action = Harness()
            .startCall(hasVideo: isVideo)
            .firstReceivedAction()
        let startAction = try XCTUnwrap(action as? CXStartCallAction)
        XCTAssertEqual(startAction.isVideo, isVideo)
        XCTAssertEqual(startAction.contactIdentifier, "TITLE")
        XCTAssertEqual(startAction.handle.type, .generic)
        XCTAssertEqual(startAction.handle.value, "base")
    }
    
    func test_StartCall_isVideo_false_notifiesCallController() throws {
        let isVideo = false
        let action = Harness()
            .startCall(hasVideo: isVideo)
            .firstReceivedAction()
        let startAction = try XCTUnwrap(action as? CXStartCallAction)
        XCTAssertEqual(startAction.isVideo, isVideo)
        XCTAssertEqual(startAction.contactIdentifier, "TITLE")
        XCTAssertEqual(startAction.handle.type, .generic)
        XCTAssertEqual(startAction.handle.value, "base")
    }
    
    func test_AnswerCall_notifiesCallController() throws {
        let harness = Harness()
        harness.sut.answerCall(in: .testEntity, withUUID: .testUUID)
        let action = try XCTUnwrap(harness.firstReceivedAction() as? CXAnswerCallAction)
        XCTAssertEqual(action.callUUID, .testUUID)
    }
    
    func test_endCall_notifiesCallController() throws {
        let harness = Harness()
        harness.sut.startCall(
            with: CallActionSync(
                chatRoom: .testEntity
            )
        )
        harness.sut.endCall(in: .testEntity, endForAll: true)
        let action = try XCTUnwrap(harness.lastReceivedAction() as? CXEndCallAction)
        XCTAssertEqual(action.callUUID, .testUUID)
    }
    
    func test_StartCall_thenReadingCallData() throws {
        let harness = Harness().startCall()
        let callAction = try XCTUnwrap(harness.sut.call(forUUID: .testUUID))
        XCTAssertEqual(callAction.chatRoom, .testEntity)
    }
    
    func test_removeCall_cleansStorage() throws {
        let harness = Harness().startCall()
        harness.sut.removeCall(withUUID: .testUUID)
        XCTAssertNil(harness.sut.call(forUUID: .testUUID))
    }
    
    func test_removeAllCalls_cleansStorage() throws {
        let harness = Harness().startCall()
        harness.sut.removeAllCalls()
        XCTAssertNil(harness.sut.call(forUUID: .testUUID))
    }
    
    func test_updateCall_updatesStorage() throws {
        let harness = Harness().startCall()
        harness.sut.updateCall(withUUID: .testUUID, muted: true)
        let callMuted = try XCTUnwrap(harness.sut.call(forUUID: .testUUID))
        XCTAssertFalse(callMuted.audioEnabled)
        harness.sut.updateCall(withUUID: .testUUID, muted: false)
        let callUnmuted = try XCTUnwrap(harness.sut.call(forUUID: .testUUID))
        XCTAssertTrue(callUnmuted.audioEnabled)
    }
}
