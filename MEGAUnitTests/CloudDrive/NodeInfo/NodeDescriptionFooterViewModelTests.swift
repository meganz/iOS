@testable import MEGA
import XCTest

final class NodeDescriptionFooterViewModelTests: XCTestCase {

    func testInitState_whenSet_shouldMatchResults() {
        let sut = NodeDescriptionFooterViewModel(leadingText: "", description: "", maxCharactersAllowed: 0)
        XCTAssertEqual(sut.leadingText, "")
        XCTAssertEqual(sut.trailingText, nil)
        XCTAssertEqual(sut.description, "")
    }

    func testShowTrailingText_withInitialValue_shouldMatchResults() {
        let sut = NodeDescriptionFooterViewModel(
            leadingText: "",
            description: "any description",
            maxCharactersAllowed: 300
        )
        sut.showTrailingText()
        XCTAssertEqual(sut.trailingText, "15/300")
    }

    func testShowTrailingText_withUpdatedDescription_shouldMatchResults() {
        let sut = NodeDescriptionFooterViewModel(
            leadingText: "",
            description: "",
            maxCharactersAllowed: 300
        )
        sut.showTrailingText()
        XCTAssertEqual(sut.trailingText, "0/300")
        sut.description = "any description"
        XCTAssertEqual(sut.trailingText, "0/300")
        sut.showTrailingText()
        XCTAssertEqual(sut.trailingText, "15/300")
    }
}
