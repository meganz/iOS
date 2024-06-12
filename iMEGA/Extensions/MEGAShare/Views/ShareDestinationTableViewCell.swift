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
        
        let color = MEGAAppColor.Black._000000.uiColor
        
        if showActivityIndicator {
            nameLabel.textColor = color.withAlphaComponent(0.5)
            tintColor = color.withAlphaComponent(0.5)
            
            let activityIndicator = UIActivityIndicatorView.mnz_init()
            activityIndicator.startAnimating()
            accessoryView = activityIndicator
            accessoryType = .none
        } else {
            nameLabel.textColor = color
            tintColor = color
            accessoryView = nil
            accessoryType = .disclosureIndicator
        }
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        backgroundColor = MEGAAppColor.White._FFFFFF_pageBackground.uiColor
    }
}
