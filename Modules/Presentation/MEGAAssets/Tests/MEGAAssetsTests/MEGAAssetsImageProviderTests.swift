@testable import MEGAAssets
import SwiftUI
import Testing
import UIKit

@Suite("MEGAAssetsPreviewImageProviderTests")
struct MEGAAssetsPreviewImageProviderTests {
    @Suite("calls image(named:String)")
    struct CallsImageNamedWithString {
        @Test("named string does not relate to a valid asset")
        func testImageNamed_withNotFoundImageName_returnsNil() {
            let notFoundImage: UIImage? = MEGAAssetsImageProvider.image(named: "any-not-found-image-name-from-MEGAAssets")
            #expect(notFoundImage == nil, "Expect image should not found.")
        }
    }
    
    @Suite("calls image(named:MEGAAssetsImageName)")
    struct CallsImageNamedWithMEGAAssetsImageName {
        @Test("when given all named assets, it should return an UIImage", arguments: MEGAAssetsImageName.allCases)
        func allMEGAAssetsImageNameShouldReturnUIImageAsset(imageName: MEGAAssetsImageName) {
            let imageFound: UIImage = MEGAAssetsImageProvider.image(named: imageName)
            #expect(imageFound != UIImage(), "Expected UIImage found.")
        }
    }
}
