import UIKit

class NodeInfoActionTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    func configureLinkCell(forNode node: MEGANode) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)

        iconImageView.image = UIImage(named: "link")
        iconImageView.tintColor = UIColor.mnz_primaryGray(for: self.traitCollection)
        if node.isExported() {
            titleLabel.text = AMLocalizedString("manageLink", "Item menu option upon right click on one or multiple files.")
        } else {
            titleLabel.text = AMLocalizedString("getLink", "Title shown under the action that allows you to get a link to file or folder")
        }
        subtitleLabel.isHidden = true
        separatorView.backgroundColor = UIColor.mnz_separator(for: self.traitCollection)
        separatorView.isHidden = true
    }
    
    func configureVersionsCell(forNode node: MEGANode) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)

        iconImageView.image = UIImage(named: "versions")
        iconImageView.tintColor = UIColor.mnz_primaryGray(for: self.traitCollection)
        titleLabel.text = AMLocalizedString("versions", "Title of section to display number of all historical versions of files.")
        subtitleLabel.text = String(node.mnz_numberOfVersions())
        subtitleLabel.isHidden = false
        separatorView.backgroundColor = UIColor.mnz_separator(for: self.traitCollection)
        separatorView.isHidden = true
        accessoryType = .disclosureIndicator
    }
}
