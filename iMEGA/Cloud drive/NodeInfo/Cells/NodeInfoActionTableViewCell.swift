import UIKit

class NodeInfoActionTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    func configureLinkCell(forNode node: MEGANode) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)

        iconImageView.image = Asset.Images.Generic.link.image
        iconImageView.tintColor = UIColor.mnz_primaryGray(for: self.traitCollection)
        if node.isExported() {
            titleLabel.text = Strings.Localizable.General.MenuAction.ManageLink.title(1)
        } else {
            titleLabel.text = Strings.Localizable.General.MenuAction.ShareLink.title(1)
        }
        subtitleLabel.isHidden = true
        separatorView.backgroundColor = UIColor.mnz_separator(for: self.traitCollection)
        separatorView.isHidden = true
    }
    
    func configureVersionsCell(forNode node: MEGANode) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)

        iconImageView.image = Asset.Images.Generic.versions.image
        iconImageView.tintColor = UIColor.mnz_primaryGray(for: self.traitCollection)
        titleLabel.text = Strings.Localizable.versions
        subtitleLabel.text = String(node.mnz_numberOfVersions() - 1)
        subtitleLabel.isHidden = false
        separatorView.backgroundColor = UIColor.mnz_separator(for: self.traitCollection)
        separatorView.isHidden = true
        accessoryType = .disclosureIndicator
    }
}
