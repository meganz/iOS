import MEGASwift
import UIKit

extension UIAction {
    public static func ~~ (lhs: UIAction, rhs: UIAction) -> Bool {
        var state = lhs.identifier == rhs.identifier && lhs.state == rhs.state && lhs.title == rhs.title && lhs.image ~~ rhs.image && lhs.attributes == rhs.attributes
        state = state && lhs.subtitle == rhs.subtitle
        return state
    }
}
