import UIKit

extension UIMenuElement {
    public func compare(_ menuElement: UIMenuElement?) -> Bool {
        guard let newMenu = menuElement else { return false }
        let status = self.title == newMenu.title && UIImage.compareImages(self.image, menuElement?.image)
        if #available(iOS 15.0, *) {
            return  status && (self.subtitle == newMenu.subtitle)
        } else {
            return status
        }
    }
}
