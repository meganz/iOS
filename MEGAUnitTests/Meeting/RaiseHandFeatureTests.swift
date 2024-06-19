@testable import MEGA
import XCTest

final class RaiseHandFeatureTests: XCTestCase {
    func testRaiseHand_IsNotActive_whenFFOff() {
        XCTAssertFalse(moreButtonVisibleInCallControls(isOneToOne: false, raiseHandFeatureEnabled: false))
        XCTAssertFalse(moreButtonVisibleInCallControls(isOneToOne: true, raiseHandFeatureEnabled: false))
    }
    
    func testRaiseHand_IsActive_NotOneOnOn_FFOn() {
        XCTAssertTrue(moreButtonVisibleInCallControls(isOneToOne: false, raiseHandFeatureEnabled: true))
    }
    
    func testRaiseHand_IsNotActive_OneOnOn_FFOn() {
        XCTAssertFalse(moreButtonVisibleInCallControls(isOneToOne: true, raiseHandFeatureEnabled: true))
    }
}
