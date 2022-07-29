import UIKit

extension UIImage {
    
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
    
    func shrinkedImageData(docScanQuality: DocScanQuality) -> Data? {
        let maxSize = CGFloat(docScanQuality.imageSize)
        let width = self.size.width;
        let height = self.size.height;
        var newWidth = width;
        var newHeight = height;
        if (width > maxSize || height > maxSize) {
            if (width > height) {
                newWidth = maxSize;
                newHeight = (height * maxSize) / width;
            } else {
                newHeight = maxSize;
                newWidth = (width * maxSize) / height;
            }
        }
        return self.resize(to: CGSize(width: newWidth / UIScreen.main.scale, height: newHeight / UIScreen.main.scale)).jpegData(compressionQuality: CGFloat(docScanQuality.rawValue))
        
    }
    
    func alpha(value: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
