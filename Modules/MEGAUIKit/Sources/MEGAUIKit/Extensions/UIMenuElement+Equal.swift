import UIKit

extension UIMenuElement {
    public func compare(_ menuElement: UIMenuElement?) -> Bool {
        guard let newMenu = menuElement else { return false }
        let status = self.title == newMenu.title && self.image?.pngData() == newMenu.image?.pngData()
        if #available(iOS 15.0, *) {
            return  status && (self.subtitle == newMenu.subtitle)
        } else {
            return status
        }
    }
}
