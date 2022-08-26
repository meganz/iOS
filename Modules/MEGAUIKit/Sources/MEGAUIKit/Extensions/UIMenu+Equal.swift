import UIKit

extension UIMenu {
    
    /// Method to compare two UIMenu objects
    /// - Parameters:
    ///   - item1: UIMenu object
    ///   - item2: UIMenu object
    /// - Returns: True if equal else False
    public static func compareMenuItem(_ item1: UIMenu?, _ item2: UIMenu?) -> Bool {
        if item1 != item2 {
            guard let item1 = item1 else { return false }
            guard let item2 = item2 else { return false }
            return item1.compare(item2)
        }
        return true
    }
    
    public func compare(_ menu: UIMenu) -> Bool {
        var status = self.options == menu.options && self.children.count == menu.children.count
        if status {
            self.children.enumerated().forEach { (index, element) in
                status = status && element.isEqual(menu.children[index])
            }
        }
        return status
    }
}
