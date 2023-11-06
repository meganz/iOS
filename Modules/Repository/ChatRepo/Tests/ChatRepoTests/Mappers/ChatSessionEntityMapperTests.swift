import ChatRepoMock
import MEGAChatSdk
import MEGADomain
import XCTest

final class ChatSessionEntityMapperTests: XCTestCase {
    func testChatSessionEntity_forDifferentMEGAChatSessionStatus_shouldReturnsCorrectMapping() {
        let types: [MEGAChatSessionStatus] = [
            .invalid,
            .inProgress,
            .destroyed
        ]
        for type in types {
            let sut = MockMEGAChatSession(status: type).toChatSessionEntity()
            switch type {
            case .invalid:
                XCTAssertEqual(sut.statusType, .invalid)
            case .inProgress:
                XCTAssertEqual(sut.statusType, .inProgress)
            case .destroyed:
                XCTAssertEqual(sut.statusType, .destroyed)
            default: break
            }
        }
    }
    
    func testChatSessionEntity_forDifferentMEGAChatSessionTermCode_shouldReturnsCorrectMapping() {
        let types: [MEGAChatSessionTermCode] = [
            .invalid,
            .recoverable,
            .nonRecoverable
        ]
        for type in types {
            let sut = MockMEGAChatSession(termCode: type).toChatSessionEntity()
            switch type {
            case .invalid:
                XCTAssertEqual(sut.termCode, .invalid)
            case .recoverable:
                XCTAssertEqual(sut.termCode, .recoverable)
            case .nonRecoverable:
                XCTAssertEqual(sut.termCode, .nonRecoverable)
            default: break
            }
        }
    }
    
    func testChatSessionEntity_forHasCamera_shouldReturnHasCameraTrue() {
        let sut = MockMEGAChatSession(hasCamera: true).toChatSessionEntity()
        XCTAssertTrue(sut.hasCamera)
    }
    
    func testChatSessionEntity_forHasNoCamera_shouldReturnHasCameraFalse() {
        let sut = MockMEGAChatSession(hasCamera: false).toChatSessionEntity()
        XCTAssertFalse(sut.hasCamera)
    }
    
    func testChatSessionEntity_forLowResCamera_shouldReturnIsLowResCameraTrue() {
        let sut = MockMEGAChatSession(isLowResCamera: true).toChatSessionEntity()
        XCTAssertTrue(sut.isLowResCamera)
    }
    
    func testChatSessionEntity_forNotLowResCamera_shouldReturnIsLowResCameraFalse() {
        let sut = MockMEGAChatSession(isLowResCamera: false).toChatSessionEntity()
        XCTAssertFalse(sut.isLowResCamera)
    }
    
    func testChatSessionEntity_forHighResCamera_shouldReturnIsHighResCameraTrue() {
        let sut = MockMEGAChatSession(isHiResCamera: true).toChatSessionEntity()
        XCTAssertTrue(sut.isHiResCamera)
    }
    
    func testChatSessionEntity_forNotHighResCamera_shouldReturnIsHighResCameraFalse() {
        let sut = MockMEGAChatSession(isHiResCamera: false).toChatSessionEntity()
        XCTAssertFalse(sut.isHiResCamera)
    }
    
    func testChatSessionEntity_forHasScreenShare_shouldReturnHasScreenShareTrue() {
        let sut = MockMEGAChatSession(hasScreenShare: true).toChatSessionEntity()
        XCTAssertTrue(sut.hasScreenShare)
    }
    
    func testChatSessionEntity_forHasNoScreenShare_shouldReturnHasScreenShareFalse() {
        let sut = MockMEGAChatSession(hasScreenShare: false).toChatSessionEntity()
        XCTAssertFalse(sut.hasScreenShare)
    }
    
    func testChatSessionEntity_forLowResScreenShare_shouldReturnIsLowResScreenShareTrue() {
        let sut = MockMEGAChatSession(isLowResScreenShare: true).toChatSessionEntity()
        XCTAssertTrue(sut.isLowResScreenShare)
    }
    
    func testChatSessionEntity_forNotLowResScreenShare_shouldReturnLowResScreenShareFalse() {
        let sut = MockMEGAChatSession(isLowResScreenShare: false).toChatSessionEntity()
        XCTAssertFalse(sut.isLowResScreenShare)
    }
    
    func testChatSessionEntity_forHighResScreenShare_shouldReturnIsHighResScreenShareTrue() {
        let sut = MockMEGAChatSession(isHiResScreenShare: true).toChatSessionEntity()
        XCTAssertTrue(sut.isHiResScreenShare)
    }
    
    func testChatSessionEntity_forNotHighResScreenShare_shouldReturnHighResScreenShareFalse() {
        let sut = MockMEGAChatSession(isHiResScreenShare: false).toChatSessionEntity()
        XCTAssertFalse(sut.isHiResScreenShare)
    }
}
