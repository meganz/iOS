import UIKit

extension UIView {

    @discardableResult
    func border(withWidth width: CGFloat) -> Self {
        layer.borderWidth = width
        return self
    }

    @discardableResult
    func border(withCornerRadius radius: CGFloat) -> Self {
        layer.cornerRadius = radius
        return self
    }

    @discardableResult
    func border(withColor color: UIColor) -> Self {
        layer.borderColor = color.cgColor
        return self
    }
}
