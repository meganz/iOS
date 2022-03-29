import XCTest
@testable import MEGA

final class PhotosBannerViewModelTests: XCTestCase {

    func testAction_photoBannerMessage() {
        let viewModel = PhotosBannerViewModel(message: "Sample Warning message")

        XCTAssertEqual(viewModel.message, "Sample Warning message")
    }
    
    func testAction_photoBannerMessage_notEmpty() {
        let viewModel = PhotosBannerViewModel(message: "Sample Warning message")

        XCTAssertTrue(!viewModel.message.isEmpty)
    }
}

