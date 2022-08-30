import UIKit

extension UIMenu {
    
    /// Method to compare two UIMenu objects
    /// - Parameters:
    ///   - item1: UIMenu object
    ///   - item2: UIMenu object
    /// - Returns: True if equal else False
    public static func compareMenuItem(_ lhs: UIMenu?, _ rhs: UIMenu?) -> Bool {
        if lhs != rhs {
            guard let lhs = lhs else { return false }
            guard let rhs = rhs else { return false }
            return lhs.compare(rhs)
        }
        return true
    }
    
    public func compare(_ menu: UIMenu) -> Bool {
        var status = self.title == menu.title && self.options == menu.options && self.children.count == menu.children.count && UIImage.compareImages(self.image, menu.image)
        if status {
            self.children.enumerated().forEach { (index, element) in
                status = status && element.compare(menu.children[index])
            }
        }
        return status
    }
}
