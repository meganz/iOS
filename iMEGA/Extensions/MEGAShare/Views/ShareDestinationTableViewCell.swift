import UIKit

class ShareDestinationTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func set(name: String,
             image: UIImage,
             isEnabled: Bool = true,
             showActivityIndicator: Bool = false) {
        
        nameLabel.text = name
        iconImageView.image = image
        isUserInteractionEnabled = isEnabled
        
        if showActivityIndicator {
            nameLabel.textColor = .gray
            tintColor = UIColor.mnz_primaryGray(for: traitCollection).withAlphaComponent(0.5)
            
            let activityIndicator = UIActivityIndicatorView.mnz_init()
            activityIndicator.startAnimating()
            accessoryView = activityIndicator
            accessoryType = .none
        } else {
            nameLabel.textColor = UIColor.mnz_primaryGray(for: traitCollection)
            tintColor = UIColor.mnz_primaryGray(for: traitCollection)
            accessoryView = nil
            accessoryType = .disclosureIndicator
        }
    }
}
