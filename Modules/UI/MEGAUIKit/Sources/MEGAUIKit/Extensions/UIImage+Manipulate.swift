import MEGASwift
import UIKit

public extension UIImage {
    
    /// Resize current image into a new image with given new size. The new image will be opaque, and scale will be current device scale.
    /// - Parameter newSize: New image's size.
    /// - Returns: A new image that has same content but with a new size.
    func resize(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    /// Will clip current image corner with given radius, if radius is `nil`, the radius will the half of min(width, height) and returns a clipped new image.
    /// - Parameter radius: Radius for clipping the corner, default value is `nil`.
    /// - Returns: A new image that with *clear* clipped corner. New image's scale will depends on device's scal.
    func withRoundedCorners(radius: CGFloat? = nil) -> UIImage {
        let maxRadius = min(size.width, size.height) / 2
        
        let cornerRadius: CGFloat
        if let radius = radius, radius >= 0 && radius <= maxRadius {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)

        return UIGraphicsGetImageFromCurrentImageContext()!
      }
    
    func alpha(value: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /// Set the tint color for an UIImage and returns it as .alwaysOriginal mode.
    /// Only applicable if the UIImage is already in `.template` rendering mode
    /// This is useful for when we want to custom tint color for icon/button in Design Token system
    /// - Parameter color: The tint color
    /// - Returns: The color with new tint color applied, with `.alwaysOriginal` as its rendering mode
    func withTintColorAsOriginal(_ color: UIColor) -> UIImage {
        withTintColor(color, renderingMode: .alwaysOriginal)
    }
}

extension UIImage: @retroactive Matchable {
    public static func ~~ (lhs: UIImage, rhs: UIImage) -> Bool {
        lhs.pngData() == rhs.pngData()
    }
}
