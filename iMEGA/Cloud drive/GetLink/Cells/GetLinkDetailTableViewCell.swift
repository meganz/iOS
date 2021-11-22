import UIKit

class GetLinkDetailTableViewCell: UITableViewCell {

    private lazy var dateFormatter = DateFormatter.dateMedium()

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var proImageView: UIImageView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var activityIndicatorContainerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    func configurePasswordCell(passwordActive: Bool, isPro: Bool, justUpgraded: Bool) {
        if passwordActive {
            nameLabel.text = NSLocalizedString("Reset Password", comment: "Text to indicate the user to reset/change the password of a link")
        } else {
            nameLabel.text = NSLocalizedString("Set Password", comment: "Text for options in Get Link View to set password protection")
        }
        nameLabel.textColor = UIColor.mnz_label()
        proImageView.isHidden = justUpgraded ? true : isPro
        detailLabel.isHidden = true
        
        accessoryType = justUpgraded ? . none : .disclosureIndicator
        activityIndicatorContainerView.isHidden = !justUpgraded
    }
    
    func configureRemovePasswordCell() {
        nameLabel.text = NSLocalizedString("Remove Password", comment: "Text to indicate the user to remove the password of a link")
        nameLabel.textColor = UIColor.mnz_red(for: traitCollection)
        proImageView.isHidden = true
        detailLabel.isHidden = true
        activityIndicatorContainerView.isHidden = true
        accessoryType = .none
    }
    
    func configureExpiryDateCell(date: Date?, dateSelected: Bool) {
        nameLabel.text =  Strings.Localizable.setExpiryDate
        nameLabel.textColor = UIColor.mnz_label()
        if let date = date {
            detailLabel.text = dateFormatter.localisedString(from: date)
        } else {
            detailLabel.text = NSLocalizedString("select", comment: "Button that allows you to select something (a folder, a message...)")
        }
        proImageView.isHidden = true
        detailLabel.isHidden = false
        detailLabel.textColor = dateSelected ? UIColor.mnz_turquoise(for: traitCollection) : UIColor.mnz_secondaryLabel()
        activityIndicatorContainerView.isHidden = true
        accessoryType = .none
    }
}
