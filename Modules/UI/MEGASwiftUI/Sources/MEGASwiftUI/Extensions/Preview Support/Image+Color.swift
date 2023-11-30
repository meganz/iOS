#if DEBUG
import SwiftUI

public extension Image {
    static func withColor(_ color: UIColor, size: CGSize) -> Image {
        Image(uiImage: .withColor(color, size: size))
    }
}

public extension UIImage {
    
    static func withColor(_ color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
#endif
