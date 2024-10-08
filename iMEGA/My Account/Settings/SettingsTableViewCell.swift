import MEGADesignToken
import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var leadingIcon: UIImageView!
    @IBOutlet weak var trailingIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var displayValueLabel: UILabel!
    
    private var isDestructive = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        displayValueLabel.textColor = UIColor.secondaryLabel
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    func update(viewModel: SettingCellViewModel) {
        isDestructive = viewModel.isDestructive
        
        leadingIcon.image = viewModel.image
        leadingIcon.isHidden = viewModel.image == nil
        titleLabel.text = viewModel.title
        titleLabel.textAlignment = isDestructive ? .center : .left
        trailingIcon.isHidden = isDestructive
        trailingIcon.tintColor = TokenColors.Icon.secondary
        displayValueLabel.text = viewModel.displayValue
        displayValueLabel.isHidden = viewModel.displayValue.isEmpty
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        titleLabel.textColor = isDestructive ? UIColor.mnz_errorRed() :
                                               UIColor.primaryTextColor()
    }
}
