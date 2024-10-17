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

        setupColors()
    }
    
    func update(viewModel: SettingCellViewModel) {
        isDestructive = viewModel.isDestructive
        
        leadingIcon.image = viewModel.image
        leadingIcon.isHidden = viewModel.image == nil
        titleLabel.text = viewModel.title
        titleLabel.textAlignment = isDestructive ? .center : .left
        trailingIcon.isHidden = isDestructive
        displayValueLabel.text = viewModel.displayValue
        displayValueLabel.isHidden = viewModel.displayValue.isEmpty
        
        setupColors()
    }
    
    private func setupColors() {
        displayValueLabel.textColor = UIColor.secondaryLabel
        trailingIcon.tintColor = TokenColors.Icon.secondary
        titleLabel.textColor = isDestructive ? TokenColors.Text.error : TokenColors.Text.primary
    }
}
