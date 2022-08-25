import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var leadingIcon: UIImageView!
    @IBOutlet weak var trailingIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var displayValueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        displayValueLabel.textColor = UIColor.mnz_secondaryLabel()
    }

    func update(viewModel: SettingCellViewModel) {
        leadingIcon.image = viewModel.image?.image
        leadingIcon.isHidden = viewModel.image == nil
        titleLabel.text = viewModel.title
        titleLabel.textColor = viewModel.isDestructive ? UIColor.mnz_red(for: self.traitCollection) : UIColor.label
        titleLabel.textAlignment = viewModel.isDestructive ? .center : .left
        trailingIcon.isHidden = viewModel.isDestructive
        displayValueLabel.text = viewModel.displayValue
        displayValueLabel.isHidden = viewModel.displayValue.isEmpty
    }
}
