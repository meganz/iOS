import UIKit

public extension UIColor {
    
    static func colorFromHexString(_ hexString: String?) -> UIColor? {
        guard let hexString else { return nil }

        var colorString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if colorString.hasPrefix("#") {
            colorString.remove(at: colorString.startIndex)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: colorString).scanHexInt64(&rgbValue)
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                       green: CGFloat((rgbValue & 0xFF00) >> 8) / 255.0,
                       blue: CGFloat(rgbValue & 0xFF) / 255.0,
                       alpha: CGFloat(1.0))
    }
    
}
