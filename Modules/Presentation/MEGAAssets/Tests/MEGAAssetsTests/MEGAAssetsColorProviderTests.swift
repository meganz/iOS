@testable import MEGAAssets
import XCTest

final class MEGAAssetsPreviewColorProviderTests: XCTestCase {
    
    func testColorNamed_withNotFoundColorName_returnsNil() {
        let notFoundColor = MEGAAssetsColorProvider.color(named: "any-not-found-color-name-from-MEGAAssets")
        
        XCTAssertNil(notFoundColor, "Expect color should not found.")
    }
}
