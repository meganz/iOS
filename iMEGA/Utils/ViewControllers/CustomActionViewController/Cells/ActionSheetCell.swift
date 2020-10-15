import UIKit

final class ActionSheetCell: UITableViewCell {

    func configureCell(action: BaseAction) {
        textLabel?.text = action.title
        detailTextLabel?.text = action.detail
        accessoryView = action.accessoryView
        imageView?.image = action.image
        switch action.style {
        case .cancel, .destructive:
            textLabel?.textColor = .mnz_red(for: traitCollection)
        default: break
        }
    }
}
