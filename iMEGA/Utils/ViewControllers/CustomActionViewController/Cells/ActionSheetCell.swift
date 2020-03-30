import UIKit

class ActionSheetCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureCell(action: ActionSheetAction) {
        textLabel?.text = action.title
        detailTextLabel?.text = action.detail
        imageView?.image = action.image
        imageView?.tintColor = #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        switch action.style {
        case .default: break
        case .cancel, .destructive:
            textLabel?.textColor = .systemRed
        default: break
        }
    }
}
