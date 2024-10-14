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
        setupColors()
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
    }
    
    private func setupColors() {
        titleLabel.textColor = isDestructive ? TokenColors.Text.error : TokenColors.Text.primary
    }
}
