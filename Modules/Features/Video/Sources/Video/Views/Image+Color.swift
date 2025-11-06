import MEGAAppPresentation
import SwiftUI

enum PreviewImageContainerFactory {
    static func withColor(_ color: UIColor, size: CGSize) -> any ImageContaining {
        let image = Image(uiImage: .withColor(color, size: size))
        let container = ImageContainer(image: image, type: .original)
        return container
    }
}

extension Image {
    static func withColor(_ color: UIColor, size: CGSize) -> Image {
        Image(uiImage: .withColor(color, size: size))
    }
}

extension UIImage {
    
    static func withColor(_ color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
