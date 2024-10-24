import MEGADesignToken
import MEGAFoundation
import MEGAL10n
import UIKit

class GetLinkDetailTableViewCell: UITableViewCell {
    
    private lazy var dateFormatter: some DateFormatting = DateFormatter.dateMedium()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var proImageView: UIImageView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var activityIndicatorContainerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        activityIndicatorView.color = TokenColors.Icon.secondary
    }

    lazy private var detailLabelSelectedTextColor: UIColor = {
        TokenColors.Text.primary
    }()
    
    func configurePasswordCell(passwordActive: Bool, isPro: Bool, justUpgraded: Bool) {
        if passwordActive {
            nameLabel.text = Strings.Localizable.resetPassword
        } else {
            nameLabel.text = Strings.Localizable.setPassword
        }
        nameLabel.textColor = TokenColors.Text.primary
        proImageView.isHidden = justUpgraded ? true : isPro
        detailLabel.isHidden = true
        
        accessoryType = justUpgraded ? . none : .disclosureIndicator
        activityIndicatorContainerView.isHidden = !justUpgraded
    }
    
    func configureRemovePasswordCell() {
        nameLabel.text = Strings.Localizable.removePassword
        nameLabel.textColor = UIColor.mnz_red()
        proImageView.isHidden = true
        detailLabel.isHidden = true
        activityIndicatorContainerView.isHidden = true
        accessoryType = .none
    }
    
    func configureExpiryDateCell(date: Date?, dateSelected: Bool) {
        nameLabel.text =  Strings.Localizable.setExpiryDate
        nameLabel.textColor = UIColor.label
        if let date = date {
            detailLabel.text = dateFormatter.localisedString(from: date)
        } else {
            detailLabel.text = Strings.Localizable.select
        }
        proImageView.isHidden = true
        detailLabel.isHidden = false
        detailLabel.textColor = dateSelected ? detailLabelSelectedTextColor : UIColor.secondaryLabel
        activityIndicatorContainerView.isHidden = true
        accessoryType = .none
    }
}
