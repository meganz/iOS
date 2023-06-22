import MEGASwift
import UIKit

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
        
        let oldMenuActions = lhs.decomposeMenuIntoActions()
        let updatedMenuActions = rhs.decomposeMenuIntoActions()
        
        return oldMenuActionTitles.elementsEqual(updatedMenuActionTitle) && matchActionStates(lhs: oldMenuActions, rhs: updatedMenuActions)
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
    
    private func decomposeMenuIntoActions() -> [UIAction] {
        children.compactMap {
            if let action = $0 as? UIAction {
                return [action]
            } else if let menu = $0 as? UIMenu {
                return menu.decomposeMenuIntoActions()
            }
            return nil
        }.reduce([], +)
    }
    
    private static func matchActionStates(lhs: [UIAction]?, rhs: [UIAction]?) -> Bool {
        guard let lhs, let rhs, lhs.count == rhs.count else { return false }
        
        let actions1 = lhs.map { ($0, $0.state) }
        let actions2 = rhs.map { ($0, $0.state) }
        
        for (index, action) in actions1.enumerated() where action != actions2[index] {
            return false
        }
        return true
    }
}
