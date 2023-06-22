import MEGASwift
import UIKit

extension UIMenuElement: Matchable {
    public static func ~~ (lhs: UIMenuElement, rhs: UIMenuElement) -> Bool {
        
        if let leftAction = lhs as? UIAction, let rightAction = rhs as? UIAction {
            return leftAction ~~ rightAction
        }
        
        if let leftMenu = lhs as? UIMenu, let rightMenu = rhs as? UIMenu {
            return leftMenu ~~ rightMenu
        }
        
        let status = lhs.title == rhs.title && lhs.image ~~ rhs.image
        if #available(iOS 15.0, *) {
            return  status && (lhs.subtitle == rhs.subtitle)
        } else {
            return status
        }
    }
}
