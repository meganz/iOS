@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ToolbarButtonsDisablerTests: XCTestCase {
    
    func testToolbarButtons_withoutDisputedNodesAndDisabled_shouldBeDisabled() {
        let sutBarButtonItem = UIBarButtonItem()

        ToolbarButtonsDisabler.disableConditionally(
            toolbarButtons: [sutBarButtonItem],
            enabled: false,
            selectedNodesArray: [NodeEntity(isTakenDown: false), NodeEntity(isTakenDown: false)]
        )

        XCTAssertFalse(sutBarButtonItem.isEnabled)
    }

    func testToolbarButtons_withDisputedNodeAndDisabled_shouldBeDisabled() {
        let sutBarButtonItem = UIBarButtonItem()

        ToolbarButtonsDisabler.disableConditionally(
            toolbarButtons: [sutBarButtonItem],
            enabled: false,
            selectedNodesArray: [NodeEntity(isTakenDown: true), NodeEntity(isTakenDown: false)]
        )

        XCTAssertFalse(sutBarButtonItem.isEnabled)
    }

    func testToolbarButtons_withoutDisputedNodesAndEnabled_shouldBeDisabled() {
        let sutBarButtonItem = UIBarButtonItem()

        ToolbarButtonsDisabler.disableConditionally(
            toolbarButtons: [sutBarButtonItem],
            enabled: true,
            selectedNodesArray: [NodeEntity(isTakenDown: false), NodeEntity(isTakenDown: false)]
        )

        XCTAssertTrue(sutBarButtonItem.isEnabled)
    }

    func testToolbarButtons_withDisputedNodeAndEnabled_shouldBeDisabled() {
        let sutBarButtonItem = UIBarButtonItem()

        ToolbarButtonsDisabler
            .disableConditionally(
            toolbarButtons: [sutBarButtonItem],
            enabled: true,
            selectedNodesArray: [NodeEntity(isTakenDown: true), NodeEntity(isTakenDown: false)]
        )

        XCTAssertFalse(sutBarButtonItem.isEnabled)
    }
}
