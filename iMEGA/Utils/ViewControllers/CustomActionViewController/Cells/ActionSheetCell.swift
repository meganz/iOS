import UIKit

final class ActionSheetCell: UITableViewCell {

    func configureCell(action: BaseAction) {
        textLabel?.text = action.title
        detailTextLabel?.text = action.detail
        if detailTextLabel?.text == "✓" {
            detailTextLabel?.textColor =  UIColor.mnz_green00A886()
        }
        imageView?.image = action.image
        switch action.style {
        case .cancel, .destructive:
            textLabel?.textColor = .systemRed
        default: break
        }
    }
}
