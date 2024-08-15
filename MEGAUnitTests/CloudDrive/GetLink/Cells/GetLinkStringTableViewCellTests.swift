@testable import MEGA
import XCTest

final class GetLinkStringTableViewCellTests: XCTestCase {
    @MainActor func testDispatch_onViewReady_configureViewCorrectly() throws {
        let title = "Test"
        let image = try XCTUnwrap(UIImage(systemName: "folder"))
        let isRightImageHidden = false
        let sut = GetLinkStringCellViewModel(type: .link, title: title, leftImage: image, isRightImageViewHidden: isRightImageHidden)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configView(title: title, leftImage: image, isRightImageViewHidden: isRightImageHidden)
        ])
    }
}
