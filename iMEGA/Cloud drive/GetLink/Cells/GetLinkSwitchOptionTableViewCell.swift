import UIKit

class GetLinkSwitchOptionTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var proImageView: UIImageView!
    @IBOutlet weak var selectorSwitch: UISwitch!
    @IBOutlet weak var activityIndicatorContainerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    func configureDecryptKeySeparatedCell(isOn: Bool, enabled: Bool) {
        nameLabel.text = NSLocalizedString("Send Decryption Key Separately", comment: "Text for options in Get Link View to separate the key from the link")
        nameLabel.alpha = enabled ? 1 : 0.3
        proImageView.isHidden = true
        selectorSwitch.isOn = isOn
        selectorSwitch.isEnabled = enabled
        activityIndicatorContainerView.isHidden = true
    }
    
    func configureActivateExpiryDateCell(isOn: Bool, isPro: Bool, justUpgraded: Bool) {
        nameLabel.text = NSLocalizedString("Expiry Date", comment: "Text for options in Get Link View to activate expiry date")
        proImageView.isHidden = justUpgraded ? true: isPro
        selectorSwitch.isHidden = justUpgraded
        selectorSwitch.isOn = isOn
        activityIndicatorContainerView.isHidden = !justUpgraded
    }
}
