import MEGADesignToken
import MEGAL10n
import UIKit

class GetLinkSwitchOptionTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var proImageView: UIImageView!
    @IBOutlet weak var selectorSwitch: UISwitch!
    @IBOutlet weak var activityIndicatorContainerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.textColor = TokenColors.Text.primary
        activityIndicatorView.color = TokenColors.Icon.secondary
        selectorSwitch.tintColor = TokenColors.Support.success
    }
    
    func configureDecryptKeySeparatedCell(isOn: Bool, enabled: Bool) {
        nameLabel.text = Strings.Localizable.sendDecryptionKeySeparately
        nameLabel.alpha = enabled ? 1 : 0.3
        proImageView.isHidden = true
        selectorSwitch.isOn = isOn
        selectorSwitch.isEnabled = enabled
        activityIndicatorContainerView.isHidden = true
    }
    
    func configureActivateExpiryDateCell(isOn: Bool, isPro: Bool, justUpgraded: Bool) {
        nameLabel.text = Strings.Localizable.expiryDate
        nameLabel.alpha = 1.0
        proImageView.isHidden = justUpgraded ? true: isPro
        selectorSwitch.isHidden = justUpgraded
        selectorSwitch.isEnabled = true
        selectorSwitch.isOn = isOn
        activityIndicatorContainerView.isHidden = !justUpgraded
    }
    
    func configure(viewModel: GetLinkSwitchOptionCellViewModel) {
        nameLabel.text = viewModel.title
        nameLabel.alpha = viewModel.isEnabled ? 1 : 0.3
        proImageView.isHidden = viewModel.isProImageViewHidden
        selectorSwitch.isOn =  viewModel.isSwitchOn
        selectorSwitch.isEnabled = viewModel.isEnabled
        activityIndicatorContainerView.isHidden = viewModel.isActivityIndicatorHidden
    }
}
