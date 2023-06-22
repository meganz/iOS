@testable import MEGA
import XCTest

final class GetLinkSwitchOptionCellViewModelTests: XCTestCase {
    func testInit_onViewConfiguration_shouldSetupCorrectly() {
        let viewConfig = GetLinkSwitchCellViewConfiguration(title: "Test")
        let expectedTye = GetLinkCellType.decryptKeySeparate
        let sut = GetLinkSwitchOptionCellViewModel(type: expectedTye, configuration: viewConfig)
        XCTAssertEqual(sut.type, expectedTye)
        XCTAssertEqual(sut.title, viewConfig.title)
        XCTAssertEqual(sut.isEnabled, viewConfig.isEnabled)
        XCTAssertEqual(sut.isProImageViewHidden, viewConfig.isProImageViewHidden)
        XCTAssertEqual(sut.isSwitchOn, viewConfig.isSwitchOn)
        XCTAssertEqual(sut.isActivityIndicatorHidden, viewConfig.isActivityIndicatorHidden)
    }
}
