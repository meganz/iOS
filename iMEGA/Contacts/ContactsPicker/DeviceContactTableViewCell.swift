
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

        selectionImage.image = selected ? UIImage(named: "thumbnail_selected") : UIImage(named: "checkBoxUnselected")
    }

    func configure(for contact: DeviceContact) {
        titleLabel.text = contact.name
        subtitleLabel.text = contact.value
        if let label = contact.valueLabel {
            descriptionLabel.text = CNLabeledValue<NSString>.localizedString(forLabel: label)
        }
        if let imageData = contact.avatarData {
            avatarImage.image = UIImage(data: imageData)
        } else {
            avatarImage.image = UIImage(named: "icon-contacts")
        }
    }
}
