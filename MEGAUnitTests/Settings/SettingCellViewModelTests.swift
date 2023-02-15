import XCTest
@testable import MEGA
import MEGAPresentation

class SettingCellViewModelTests: XCTestCase {
    var sut: SettingCellViewModel!
    
    override func setUpWithError() throws {
        sut = SettingCellViewModel(image: nil, title: "", isDestructive: Bool.random(), displayValue: "", router: nil)
    }

    func testUpdateDisplayValue() {
        XCTAssertEqual(sut.displayValue, "")
        XCTAssertNil(sut.invokeCommand)
        var value: Bool?
        XCTAssertNil(value)
        sut.invokeCommand = { cmd in
            if cmd == .reloadData {
                value = true
            }
        }
        sut.updateDisplayValue(self.description)
        XCTAssertEqual(sut.displayValue, self.description)
        XCTAssertNotNil(value)
    }

    func testUpdateRouter() {
        XCTAssertNil(sut.router)
        sut.updateRouter(router: MockRouter())
        XCTAssertNotNil(sut.router)
    }
    
    private struct MockRouter: Routing {}
}
