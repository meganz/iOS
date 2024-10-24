import MEGADesignToken
import MEGAL10n
import UIKit

class GetLinkAccessInfoTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.textColor = TokenColors.Text.secondary
        descriptionLabel.textColor = TokenColors.Text.primary
    }

    func configure(nodesCount: Int, isPasswordSet: Bool) {
        descriptionLabel.text = isPasswordSet ? Strings.Localizable.SharedItems.Link.accessInfoPasswordProtected
        : Strings.Localizable.SharedItems.Link.accessInfo(nodesCount)
    }
}
