import UIKit

class GetLinkDetailTableViewCell: UITableViewCell {

    private lazy var dateFormatter = DateFormatter.dateMedium()

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!

    func configurePasswordCell(passwordActive: Bool, enabled: Bool) {
        if passwordActive {
            nameLabel.text = AMLocalizedString("Reset Password", "Text to indicate the user to reset/change the password of a link")
        } else {
            nameLabel.text = AMLocalizedString("Set Password", "Text for options in Get Link View to set password protection")
        }
        nameLabel.textColor = UIColor.mnz_label()
        nameLabel.alpha = enabled ? 1 : 0.3
        detailLabel.isHidden = true
        accessoryType = .disclosureIndicator
        selectionStyle = enabled ? .default : .none
    }
    
    func configureRemovePasswordCell() {
        nameLabel.text = AMLocalizedString("Remove Password", "Text to indicate the user to remove the password of a link")
        nameLabel.textColor = UIColor.mnz_red(for: traitCollection)
        detailLabel.isHidden = true
        accessoryType = .none
    }
    
    func configureExpiryDateCell(date: Date?, dateSelected: Bool) {
        nameLabel.text = AMLocalizedString("Set Expiry Date", "Text for options in Get Link View to set expiry date")
        nameLabel.textColor = UIColor.mnz_label()
        if let date = date {
            detailLabel.text = dateFormatter.localisedString(from: date)
        } else {
            detailLabel.text = AMLocalizedString("select", "Button that allows you to select something (a folder, a message...)")
        }
        detailLabel.isHidden = false
        detailLabel.textColor = dateSelected ? UIColor.mnz_turquoise(for: traitCollection) : UIColor.mnz_secondaryLabel()
        accessoryType = .none
    }
}
