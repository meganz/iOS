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
    
    public static func match(lhs: UIMenu?, rhs: UIMenu?) -> Bool {
        guard let lhs, let rhs else { return false }
        
        let oldMenuActionTitles = lhs.decomposeMenuIntoActionTitles()
        let updatedMenuActionTitle = rhs.decomposeMenuIntoActionTitles()
        
        return oldMenuActionTitles.elementsEqual(updatedMenuActionTitle)
    }
    
    private func decomposeMenuIntoActionTitles() -> [String] {
        children.compactMap {
            if let action = $0 as? UIAction {
                return [action.title]
            } else if let menu = $0 as? UIMenu {
                return menu.decomposeMenuIntoActionTitles()
            }
            return nil
        }.reduce([], +)
    }
}
