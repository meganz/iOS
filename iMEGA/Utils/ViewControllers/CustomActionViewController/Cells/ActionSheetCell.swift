import UIKit

final class ActionSheetCell: UITableViewCell {

    func configureCell(action: BaseAction) {
        textLabel?.text = action.title
        detailTextLabel?.text = action.detail
        accessoryView = action.accessoryView
        if detailTextLabel?.text == "✓" {
            detailTextLabel?.textColor =  UIColor.mnz_green00A886()
        }
        imageView?.image = action.image
        imageView?.tintColor = #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        switch action.style {
        case .cancel, .destructive:
            textLabel?.textColor = .systemRed
            imageView?.tintColor = .systemRed
        default: break
        }
    }
}
