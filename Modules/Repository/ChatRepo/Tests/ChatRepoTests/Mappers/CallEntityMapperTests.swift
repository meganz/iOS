import ChatRepoMock
import MEGAChatSdk
import MEGADomain
import XCTest

final class CallEntityMapperTests: XCTestCase {
    func testCallEntity_forDifferentChatCallStatus_shouldReturnsCorrectMapping() {
        let types: [MEGAChatCallStatus] = [
            .undefined,
            .initial,
            .userNoPresent,
            .connecting,
            .waitingRoom,
            .joining,
            .inProgress,
            .terminatingUserParticipation,
            .destroyed
        ]
        for type in types {
            let sut = MockMEGAChatCall(status: type).toCallEntity()
            switch type {
            case .undefined:
                XCTAssertEqual(sut.status, .undefined)
            case .initial:
                XCTAssertEqual(sut.status, .initial)
            case .userNoPresent:
                XCTAssertEqual(sut.status, .userNoPresent)
            case .connecting:
                XCTAssertEqual(sut.status, .connecting)
            case .waitingRoom:
                XCTAssertEqual(sut.status, .waitingRoom)
            case .joining:
                XCTAssertEqual(sut.status, .joining)
            case .inProgress:
                XCTAssertEqual(sut.status, .inProgress)
            case .terminatingUserParticipation:
                XCTAssertEqual(sut.status, .terminatingUserParticipation)
            case .destroyed:
                XCTAssertEqual(sut.status, .destroyed)
            default: break
            }
        }
    }
    
    func testCallEntity_forDifferentChatCallChangeType_shouldReturnsCorrectMapping() {
        let types: [MEGAChatCallChangeType] = [
            .noChanges,
            .status,
            .localAVFlags,
            .ringingStatus,
            .callComposition,
            .callOnHold,
            .callSpeak,
            .audioLevel,
            .networkQuality,
            .outgoingRingingStop,
            .ownPermissions,
            .genericNotification,
            .waitingRoomAllow,
            .waitingRoomDeny,
            .waitingRoomComposition,
            .waitingRoomUsersEntered,
            .waitingRoomUsersLeave,
            .waitingRoomUsersAllow,
            .waitingRoomUsersDeny,
            .waitingRoomPushedFromCall
        ]
        for type in types {
            let sut = MockMEGAChatCall(changes: type).toCallEntity()
            switch type {
            case .noChanges:
                XCTAssertEqual(sut.changeType, .noChanges)
            case .status:
                XCTAssertEqual(sut.changeType, .status)
            case .localAVFlags:
                XCTAssertEqual(sut.changeType, .localAVFlags)
            case .ringingStatus:
                XCTAssertEqual(sut.changeType, .ringingStatus)
            case .callComposition:
                XCTAssertEqual(sut.changeType, .callComposition)
            case .callOnHold:
                XCTAssertEqual(sut.changeType, .onHold)
            case .callSpeak:
                XCTAssertEqual(sut.changeType, .callSpeak)
            case .audioLevel:
                XCTAssertEqual(sut.changeType, .audioLevel)
            case .networkQuality:
                XCTAssertEqual(sut.changeType, .networkQuality)
            case .outgoingRingingStop:
                XCTAssertEqual(sut.changeType, .outgoingRingingStop)
            case .ownPermissions:
                XCTAssertEqual(sut.changeType, .ownPermission)
            case .genericNotification:
                XCTAssertEqual(sut.changeType, .genericNotification)
            case .waitingRoomAllow:
                XCTAssertEqual(sut.changeType, .waitingRoomAllow)
            case .waitingRoomDeny:
                XCTAssertEqual(sut.changeType, .waitingRoomDeny)
            case .waitingRoomComposition:
                XCTAssertEqual(sut.changeType, .waitingRoomComposition)
            case .waitingRoomUsersEntered:
                XCTAssertEqual(sut.changeType, .waitingRoomUsersEntered)
            case .waitingRoomUsersLeave:
                XCTAssertEqual(sut.changeType, .waitingRoomUsersLeave)
            case .waitingRoomUsersAllow:
                XCTAssertEqual(sut.changeType, .waitingRoomUsersAllow)
            case .waitingRoomUsersDeny:
                XCTAssertEqual(sut.changeType, .waitingRoomUsersDeny)
            case .waitingRoomPushedFromCall:
                XCTAssertEqual(sut.changeType, .waitingRoomPushedFromCall)
            default: break
            }
        }
    }
}
