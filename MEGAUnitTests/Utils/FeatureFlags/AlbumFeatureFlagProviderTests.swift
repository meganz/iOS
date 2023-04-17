import XCTest
@testable import MEGA

final class AlbumFeatureFlagProviderTests: XCTestCase {
    private let underTest = AlbumFeatureFlagProvider()
    
    func testIsFeatureFlagEnabled_onCreateAlbumOrAlbumContextMenu_shouldBeEnabled() {
        XCTAssertTrue(underTest.isFeatureFlagEnabled(for: .createAlbum))
        XCTAssertTrue(underTest.isFeatureFlagEnabled(for: .albumContextMenu))
    }

    func testIsFeatureFlagEnabled_onOtherToggles_shouldBeTurnedOff() {
        var features = FeatureFlagKey.allCases
        features.remove(object: .createAlbum)
        features.remove(object: .albumContextMenu)
        features.forEach {
            XCTAssertFalse(underTest.isFeatureFlagEnabled(for: $0))
        }
    }
}
