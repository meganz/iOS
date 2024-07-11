@testable import MEGA
import XCTest

final class SnackBarTests: XCTestCase {
    func test_WithSupplementalAction_CalledAfterAction() {
        var originalHandlerCalled = false
        var supplementalActionCalled = false
        let snackBar = SnackBar(
            message: "M",
            layout: .horizontal,
            action: .init(
                title: "Action",
                handler: {
                    originalHandlerCalled = true
                }
            ),
            colors: .default
        )
        
        let modified = snackBar.withSupplementalAction {
            supplementalActionCalled = true
        }
        
        modified.action?.handler()
        XCTAssertTrue(originalHandlerCalled)
        XCTAssertTrue(supplementalActionCalled)
    }
    
    func test_WithSupplementalAction_NotCalledWhenActionIsNil() {
        var supplementalActionCalled = false
        let snackBar = SnackBar(
            message: "M",
            layout: .horizontal,
            action: nil,
            colors: .default
        )
        
        let modified = snackBar.withSupplementalAction {
            supplementalActionCalled = true
        }
        
        modified.action?.handler()
        XCTAssertFalse(supplementalActionCalled)
    }
}
