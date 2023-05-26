import UIKit
import MEGASwift

extension UIAction {
    public static func ~~ (lhs: UIAction, rhs: UIAction) -> Bool {
        var state = lhs.identifier == rhs.identifier && lhs.state == rhs.state && lhs.title == rhs.title && lhs.image ~~ rhs.image && lhs.attributes == rhs.attributes
        if #available(iOS 15.0, *) {
            state = state && lhs.subtitle == rhs.subtitle
        }
        return state
    }
}
