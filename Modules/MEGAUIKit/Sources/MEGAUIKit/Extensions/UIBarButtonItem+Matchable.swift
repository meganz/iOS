import UIKit
import MEGASwift

extension UIBarButtonItem: Matchable {
    
    public static func ~~ (lhs: UIBarButtonItem, rhs: UIBarButtonItem) -> Bool {
        var status = true
         status = status && lhs.title == rhs.title && lhs.image ~~ rhs.image && lhs.style == rhs.style
        if #available(iOS 14.0, *) {
            status = status && lhs.menu ~~ rhs.menu
        }
        return status
    }
}
