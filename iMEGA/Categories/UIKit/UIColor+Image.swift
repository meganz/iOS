import UIKit

extension UIColor {

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
