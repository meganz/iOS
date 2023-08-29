public struct MEGAAssets {
    public init() {}
}

import UIKit
public class MEGAAssetsImageProvider {
    // for any image located in bundle where this class has built
    public static func image(named: String) -> UIImage? {
        return UIImage(named: named, in: Bundle(for: self), with: nil)
    }
}
