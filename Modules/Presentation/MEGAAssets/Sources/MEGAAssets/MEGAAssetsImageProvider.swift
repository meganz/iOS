import UIKit

/// A provider type to access MEGAAssets image by it's name for SPM support. At the moment, SPM does not support assets extension (e.g. UIImage.myImageNameFromAssets), thus, this provider hepls to simplify the access, wrapping bundle reference.
public class MEGAAssetsImageProvider {
    
    /// Static function to get image of MEGAAssets. See `MEGAAssetsImageProviderTests.testImageNamed_withNotFoundImageName_returnsNil()` to check how to use this API.
    /// - Parameter named: your desired image name from MEGAAssets
    /// - Returns: A nullalbe UIImage. Returns nil if the image is not found.
    public static func image(named: String) -> UIImage? {
        return UIImage(named: named, in: .module, with: nil)
    }
}
