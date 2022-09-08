import UIKit
import MEGASwift

extension UIMenuElement: Matchable {
    public static func ~~ (lhs: UIMenuElement, rhs: UIMenuElement) -> Bool {
        let status = lhs.title == rhs.title && lhs.image ~~ rhs.image
        if #available(iOS 15.0, *) {
            return  status && (lhs.subtitle == rhs.subtitle)
        } else {
            return status
        }
    }
}
