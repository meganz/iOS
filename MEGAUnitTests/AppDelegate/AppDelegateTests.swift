@testable import MEGA
import XCTest

@MainActor
final class AppDelegateTests: XCTestCase {
    
    func testMatchQuickAction_withMatchingType_shouldReturnTrue() {
        let inputType = "mega.ios.upload"
        let type = "upload"
        XCTAssertTrue(AppDelegate.matchQuickAction(inputType, with: type))
    }
    
    func testMatchQuickAction_withMatchingTypeWithSubtype_shouldReturnTrue() {
        let inputType = "mega.ios.qa.offline"
        let type = "offline"
        XCTAssertTrue(AppDelegate.matchQuickAction(inputType, with: type))
    }
    
    func testMatchQuickAction_withNonMatchingType_shouldReturnFalse() {
        let inputType = "other.ios.upload"
        let type = "offline"
        XCTAssertFalse(AppDelegate.matchQuickAction(inputType, with: type))
    }
    
}
