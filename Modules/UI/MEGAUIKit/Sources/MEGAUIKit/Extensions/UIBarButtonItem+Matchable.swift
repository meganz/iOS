import MEGASwift
import UIKit

extension UIBarButtonItem: @retroactive Matchable {
    
    public static func ~~ (lhs: UIBarButtonItem, rhs: UIBarButtonItem) -> Bool {
        var status = true
         status = status && lhs.title == rhs.title && lhs.image ~~ rhs.image && lhs.style == rhs.style
        status = status && lhs.menu ~~ rhs.menu
        return status
    }
}
