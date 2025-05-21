@testable import MEGAAssets
import SwiftUI
import Testing
import UIKit

@Suite("MEGAAssetsPreviewImageProviderTests")
struct MEGAAssetsPreviewImageProviderTests {
    @Test("named string does not relate to a valid asset")
    func testImageNamed_withNotFoundImageName_returnsNil() {
        let notFoundImage: UIImage? = MEGAAssets.UIImage.image(named: "any-not-found-image-name-from-MEGAAssets")
        #expect(notFoundImage == nil, "Expect image should not found.")
    }
    
    @Test("when given all named assets, it should return an UIImage", arguments: MEGAAssetsFileType.allCases)
    func allMEGAAssetsFileTypeImageNameShouldReturnUIImageAsset(fileType: MEGAAssetsFileType) {
        let imageFound: UIImage? = MEGAAssets.UIImage.image(forAssetsFileType: fileType)
        #expect(imageFound != UIImage(), "Expected UIImage found.")
    }
}
