import UIKit

public extension UIColor {

    var hexString: String {
        let components = cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
     }
    
    /// Will generate an `UIImage` with given size filled by invoker `UIColor`(self).
    /// - Parameter size: `CGSize` instance, size of the image. Image will fill from point (0, 0) - origin.
    /// - Returns: An `UIImage` with given size filled by invoker color.
    func image(withSize size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            setFill()
            context.fill(CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        }
    }
}
