@testable import MEGAAssets
import XCTest

final class MEGAAssetsPreviewImageProviderTests: XCTestCase {
    
    func testImageNamed_withNotFoundImageName_returnsNil() {
        let notFoundImage = MEGAAssetsImageProvider.image(named: "any-not-found-image-name-from-MEGAAssets")
        
        XCTAssertNil(notFoundImage, "Expect image should not found.")
    }
}
