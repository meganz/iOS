@testable import MEGA
import MEGADomain
import XCTest

final class RaiseHandDiffingTests: XCTestCase {
    
    func testApplyingRaisedHands_EmptyInputs_NoChanges() {
        let result = RaiseHandDiffing.applyingRaisedHands(
            callParticipantHandles: [],
            raiseHandListBefore: [],
            raiseHandListAfter: []
        )
        XCTAssertTrue(result.isEmpty)
    }
    
    func testApplyingRaisedHands_SingleRaisedHand_DetectsChange() {
        let result = RaiseHandDiffing.applyingRaisedHands(
            callParticipantHandles: [1],
            raiseHandListBefore: [],
            raiseHandListAfter: [1]
        )
        
        let expected = RaiseHandDiffing.RaiseHandChange(
            handle: 1,
            raisedHand: true,
            index: 0
        )
        XCTAssertEqual(result, [expected])
    }
    
    func testApplyingRaisedHands_SingleLoweredHand_DetectsChange() {
        let result = RaiseHandDiffing.applyingRaisedHands(
            callParticipantHandles: [1, 2],
            raiseHandListBefore: [1, 2],
            raiseHandListAfter: [1]
        )
        
        let expected = RaiseHandDiffing.RaiseHandChange(
            handle: 2,
            raisedHand: false,
            index: 1
        )
        XCTAssertEqual(result, [expected])
    }
    
    func testApplyingRaisedHands_LoweredAndRaisedHand_DetectsChange() {
        let result = RaiseHandDiffing.applyingRaisedHands(
            callParticipantHandles: [1, 2, 3],
            raiseHandListBefore: [1, 2],
            raiseHandListAfter: [1, 3]
        )
        
        let expected = [
            RaiseHandDiffing.RaiseHandChange(
                handle: 2,
                raisedHand: false,
                index: 1
            ),
            RaiseHandDiffing.RaiseHandChange(
                handle: 3,
                raisedHand: true,
                index: 2
            )
        ]
        XCTAssertEqual(Set(result), Set(expected))
    }
}
