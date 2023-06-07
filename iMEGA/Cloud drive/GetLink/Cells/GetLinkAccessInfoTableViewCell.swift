import UIKit

class GetLinkAccessInfoTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    func configure(isPasswordSet: Bool) {
        self.descriptionLabel.text = isPasswordSet ? Strings.Localizable.SharedItems.Link.accessInfoPasswordProtected :
        Strings.Localizable.SharedItems.Link.accessInfo
    }
}
