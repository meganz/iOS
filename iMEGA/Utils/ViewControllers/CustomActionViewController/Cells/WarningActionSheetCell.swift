import UIKit

final class WarningActionSheetCell: UITableViewCell {
    
    func configureCell(action: NodeAction) {
        NSLayoutConstraint.activate([heightAnchor.constraint(greaterThanOrEqualToConstant: 60.0)])
        textLabel?.text = action.title
        detailTextLabel?.text = action.detail
        accessoryView = UIImageView(image: UIImage(named: "actionWarning"))
        imageView?.image = action.image?.withRenderingMode(.alwaysTemplate)
        imageView?.tintColor = .mnz_red(for: traitCollection)
        textLabel?.textColor = .mnz_red(for: traitCollection)
    }
}
