import MEGAAssets
import UIKit

@objc extension UIImage {
    static func megaImage(named: String) -> UIImage? {
        MEGAAssets.UIImage.image(named: named)
    }
}
