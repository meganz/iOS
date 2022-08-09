
import UIKit

class DeviceContactTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var selectionImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        selectionImage.image = selected ? Asset.Images.Generic.thumbnailSelected.image : Asset.Images.Login.checkBoxUnselected.image
    }

    func configure(for contact: DeviceContact) {
        titleLabel.text = contact.name
        subtitleLabel.text = contact.contactDetail
        if let label = contact.contactDetailDescription {
            descriptionLabel.text = CNLabeledValue<NSString>.localizedString(forLabel: label)
        }
        if let imageData = contact.avatarData {
            avatarImage.image = UIImage(data: imageData)
        } else {
            avatarImage.image = Asset.Images.MyAccount.iconContacts.image
        }
    }
}
