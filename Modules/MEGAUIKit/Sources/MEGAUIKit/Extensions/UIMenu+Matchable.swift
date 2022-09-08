import UIKit
import MEGASwift

extension UIMenu {
    public static func ~~ (lhs: UIMenu, rhs: UIMenu) -> Bool {
        var status = lhs.title == rhs.title && lhs.options == rhs.options && lhs.children.count == rhs.children.count && lhs.image ~~ rhs.image
        if status {
            status = lhs.children ~~ rhs.children
        }
        return status
    }
}
