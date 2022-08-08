import UIKit

public extension UITableViewCell {
    func setSelectedBackgroundView(withColor color: UIColor) {
        let view = UIView()
        view.backgroundColor = color
        selectedBackgroundView = view
    }
}
