import UIKit

class GetLinkSwitchOptionTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var proImageView: UIImageView!
    @IBOutlet weak var selectorSwitch: UISwitch!
    @IBOutlet weak var activityIndicatorContainerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var viewModel: GetLinkSwitchOptionCellViewModel? {
        didSet {
            viewModel?.invokeCommand = { [weak self] in
                self?.executeCommand($0)
            }
            viewModel?.dispatch(.onViewReady)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
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
        proImageView.isHidden = justUpgraded ? true: isPro
        selectorSwitch.isHidden = justUpgraded
        selectorSwitch.isOn = isOn
        activityIndicatorContainerView.isHidden = !justUpgraded
    }
    
    @MainActor
    private func executeCommand(_ command: GetLinkSwitchOptionCellViewModel.Command) {
        switch command {
        case .configView(let config):
            nameLabel.text = config.title
            nameLabel.alpha = config.isEnabled ? 1 : 0.3
            proImageView.isHidden = config.isProImageViewHidden
            selectorSwitch.isOn =  config.isSwitchOn
            selectorSwitch.isEnabled = config.isEnabled
            activityIndicatorContainerView.isHidden = config.isActivityIndicatorHidden
        case .updateSwitch(let isOn):
            selectorSwitch.isOn = isOn
        }
    }
}
