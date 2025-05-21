import MEGAAssets
import MEGADesignToken
import MEGAL10n
import UIKit

class NodeInfoActionTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupColors()
    }

    private func setupColors() {
        backgroundColor = TokenColors.Background.page
        separatorView.backgroundColor = TokenColors.Border.strong
        iconImageView.tintColor = TokenColors.Icon.primary
        titleLabel.textColor = TokenColors.Text.primary
        subtitleLabel.textColor = TokenColors.Text.primary
    }
    
    func configureLinkCell(forNode node: MEGANode) {
        iconImageView.image = MEGAAssets.UIImage.link
        if node.isExported() {
            titleLabel.text = Strings.Localizable.General.MenuAction.ManageLink.title(1)
        } else {
            titleLabel.text = Strings.Localizable.General.MenuAction.ShareLink.title(1)
        }
        subtitleLabel.isHidden = true
        separatorView.isHidden = true
    }
    
    func configureVersionsCell(forNode node: MEGANode) {
        iconImageView.image = MEGAAssets.UIImage.versions
        titleLabel.text = Strings.Localizable.versions
        subtitleLabel.text = String(node.mnz_numberOfVersions() - 1)
        subtitleLabel.isHidden = false
        separatorView.isHidden = true
        accessoryType = .disclosureIndicator
    }
}
