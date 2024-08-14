import SwiftUI
import UIKit

/// A provider type to access MEGAAssets color by it's name for SPM support. At the moment, SPM does not support assets extension (e.g. UIColor.myColorNameFromAssets), thus, this provider hepls to simplify the access, wrapping bundle reference.
public class MEGAAssetsColorProvider {
    
    /// Static function to get color of MEGAAssets. See `MEGAAssetsColorProviderTests.testcolorNamed_withNotFoundColorName_returnsNil()` to check how to use this API.
    /// - Parameter named: your desired color name from MEGAAssets
    /// - Returns: A nullalbe UIColor. Returns nil if the color is not found.
    public static func color(named: String) -> UIColor? {
        return UIColor(named: named, in: .module, compatibleWith: nil)
    }
    
    public static func swiftUIColor(named: String) -> Color {
        return Color(named, bundle: .module)
    }
}
