import UIKit
import MEGASwift

extension UIBarButtonItem: Matchable {
    
    public static func ~~ (lhs: UIBarButtonItem, rhs: UIBarButtonItem) -> Bool {
        var status = true
         status = status && lhs.title == rhs.title && lhs.image ~~ rhs.image && lhs.style == rhs.style
        status = status && lhs.menu ~~ rhs.menu
        return status
    }
}
