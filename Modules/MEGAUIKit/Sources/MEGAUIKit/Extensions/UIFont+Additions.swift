import UIKit

public extension UIFont {
    static func preferredFont(style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let font = preferredFont(forTextStyle: style)
        return UIFont.systemFont(ofSize: font.pointSize, weight: weight)
    }
}
