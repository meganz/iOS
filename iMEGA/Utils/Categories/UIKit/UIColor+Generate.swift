import UIKit

extension UIColor {

    static func rgbFromBase8Color(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let base: CGFloat = 255.0
        return (CGFloat(red) / base, CGFloat(green) / base, CGFloat(blue) / base, CGFloat(alpha) / base)
    }

    static func rgbColor(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) -> UIColor {
        let (r, g, b, a) = rgbFromBase8Color(red: red, green: green, blue: blue, alpha: alpha)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
