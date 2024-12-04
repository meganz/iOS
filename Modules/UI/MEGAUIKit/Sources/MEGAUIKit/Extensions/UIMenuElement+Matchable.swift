import MEGASwift
import UIKit

extension UIMenuElement: @retroactive Matchable {
    nonisolated public static func ~~ (lhs: UIMenuElement, rhs: UIMenuElement) -> Bool {
        MainActor.assumeIsolated {
            if let leftAction = lhs as? UIAction, let rightAction = rhs as? UIAction {
                return leftAction ~~ rightAction
            }
            
            if let leftMenu = lhs as? UIMenu, let rightMenu = rhs as? UIMenu {
                return leftMenu ~~ rightMenu
            }
            
            let status = lhs.title == rhs.title && lhs.image ~~ rhs.image
            return status && (lhs.subtitle == rhs.subtitle)
        }
    }
}
