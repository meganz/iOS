import UIKit

class GetLinkSwitchOptionTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectorSwitch: UISwitch!
    
    func configureDecryptKeySeparatedCell(isOn: Bool, enabled: Bool) {
        nameLabel.text = AMLocalizedString("Send Decryption Key Separately", "Text for options in Get Link View to separate the key from the link")
        nameLabel.alpha = enabled ? 1 : 0.3
        selectorSwitch.isOn = isOn
        selectorSwitch.isEnabled = enabled
    }
    
    func configureActivateExpiryDateCell(isOn: Bool, enabled: Bool) {
        nameLabel.text = AMLocalizedString("Expiry Date", "Text for options in Get Link View to activate expiry date")
        nameLabel.alpha = enabled ? 1 : 0.3
        selectorSwitch.isOn = isOn
        selectorSwitch.isEnabled = enabled
    }
}
