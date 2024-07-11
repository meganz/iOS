@testable import MEGA
import MEGADomain
import XCTest

final class RaiseHandDiffingTests: XCTestCase {
    
    class Harness {
        var sut: RaiseHandDiffing.DiffResult
        init(
            callParticipantHandles: [HandleEntity] = [],
            raiseHandListBefore: [HandleEntity] = [],
            raiseHandListAfter: [HandleEntity] = [],
            localUserParticipantId: HandleEntity = .invalid
        ) {
            sut = RaiseHandDiffing.applyingRaisedHands(
                callParticipantHandles: callParticipantHandles,
                raiseHandListBefore: raiseHandListBefore,
                raiseHandListAfter: raiseHandListAfter,
                localUserParticipantId: localUserParticipantId
            )
        }
    }
    
    func testApplyingRaisedHands_EmptyInputs_NoChanges() {
        let sut = Harness().sut
        XCTAssertTrue(sut.changes.isEmpty)
    }
    
    func testApplyingRaisedHands_SingleRaisedHand_DetectsChange() {
        let harness = Harness(
            callParticipantHandles: [1],
            raiseHandListBefore: [],
            raiseHandListAfter: [1]
        )
        
        let expected = RaiseHandDiffing.DiffResult(
            changes: [
                .init(
                    handle: 1,
                    raisedHand: true,
                    index: 0
                )
            ],
            shouldUpdateSnackBar: true
        )
        XCTAssertEqual(harness.sut, expected)
    }
    
    func testApplyingRaisedHands_SingleLoweredHand_DetectsChange() {
        let harness = Harness(
            callParticipantHandles: [1, 2],
            raiseHandListBefore: [1, 2],
            raiseHandListAfter: [1]
        )
        
        let expected = RaiseHandDiffing.DiffResult(
            changes: [
                .init(
                    handle: 2,
                    raisedHand: false,
                    index: 1
                )
            ],
            shouldUpdateSnackBar: false
        )
        XCTAssertEqual(harness.sut, expected)
    }
    
    func testApplyingRaisedHands_LoweredAndRaisedHand_DetectsChange() {
        let harness = Harness(
            callParticipantHandles: [1, 2, 3],
            raiseHandListBefore: [1, 2],
            raiseHandListAfter: [1, 3]
        )
        
        let expected = RaiseHandDiffing.DiffResult(
            changes: [
                .init(
                    handle: 2,
                    raisedHand: false,
                    index: 1
                ),
                .init(
                    handle: 3,
                    raisedHand: true,
                    index: 2
                )
            ],
            shouldUpdateSnackBar: true
        )
        XCTAssertEqual(harness.sut, expected)
    }
    
    func testApplyingRaisedHands_Detects_ShouldUpdateSnackBar() {
        let harness = Harness(
            callParticipantHandles: [2, 3, 4],
            raiseHandListBefore: [1, 2, 3],
            raiseHandListAfter: [1, 2, 3, 4]
        )
        XCTAssertTrue(harness.sut.shouldUpdateSnackBar)
    }
    
    func testApplyingRaisedHands_LocalRaisedHand_Detects_ShouldUpdateSnackBar() {
        let harness = Harness(
            callParticipantHandles: [1, 2, 3, 4],
            raiseHandListBefore: [],
            raiseHandListAfter: [1],
            localUserParticipantId: 1
        )
        XCTAssertTrue(harness.sut.shouldUpdateSnackBar)
    }
    
    func testApplyingRaisedHands_LocalLoweredHand_Detects_ShouldUpdateSnackBar() {
        let harness = Harness(
            callParticipantHandles: [2, 3, 4],
            raiseHandListBefore: [1],
            raiseHandListAfter: [0],
            localUserParticipantId: 1
        )
        XCTAssertTrue(harness.sut.shouldUpdateSnackBar)
    }
    
    func testApplyingRaisedHands_NoRaiseHandChanged_ShouldNotUpdateSnackBar() {
        let harness = Harness(
            callParticipantHandles: [2, 3, 4],
            raiseHandListBefore: [2],
            raiseHandListAfter: [2],
            localUserParticipantId: 1
        )
        XCTAssertFalse(harness.sut.shouldUpdateSnackBar)
    }
    
    func testApplyingRaisedHands_AllHandsLowered_ShouldUpdateSnackBar() {
        let harness = Harness(
            callParticipantHandles: [2, 3, 4],
            raiseHandListBefore: [2, 3],
            raiseHandListAfter: [],
            localUserParticipantId: 1
        )
        XCTAssertTrue(harness.sut.shouldUpdateSnackBar)
    }
    
    func testApplyingRaisedHands_LocalUserLowersHand_ShouldNotUpdateSnackBar() {
        let harness = Harness(
            callParticipantHandles: [2, 3, 4],
            raiseHandListBefore: [2, 3, 1],
            raiseHandListAfter: [2, 3],
            localUserParticipantId: 1
        )
        XCTAssertFalse(harness.sut.shouldUpdateSnackBar)
    }
    
    func testHasRaisedHand_RaisedHand_ReturnsCorrectly() {
        let harness = Harness(
            callParticipantHandles: [1, 2, 3],
            raiseHandListBefore: [3, 1],
            raiseHandListAfter: [1, 2],
            localUserParticipantId: 1
        )
        
        XCTAssertTrue(harness.sut.hasRaisedHand(participantId: 2))
        XCTAssertFalse(harness.sut.hasRaisedHand(participantId: 3))
        XCTAssertFalse(harness.sut.hasRaisedHand(participantId: 1))
    }
}
