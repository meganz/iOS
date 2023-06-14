import XCTest
@testable import MEGA

final class BadgeButtonTests: XCTestCase {

    func testSetAvatarImage_onCreateBadgeButton_backgroundImageShouldNotBeNil() throws {
        let badgeButton = BadgeButton()
        XCTAssertNotNil(badgeButton.backgroundImage(for: .normal))
    }
    
    func testSetAvatarImage_onSetAvatarImage_backgroundImageShouldBeNil() throws {
        let badgeButton = BadgeButton()
        let imageRect = CGRect(origin: .zero, size: CGSize(width: 28, height: 28))
        badgeButton.setAvatarImage(UIImage(color: .gray, andBounds: imageRect))
        XCTAssertNil(badgeButton.backgroundImage(for: .normal))
    }
}
