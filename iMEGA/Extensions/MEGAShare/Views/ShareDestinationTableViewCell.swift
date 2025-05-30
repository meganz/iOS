import MEGAAppPresentation
import MEGADesignToken
import UIKit

class ShareDestinationTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    var showActivityIndicator = false
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func set(name: String,
             image: UIImage,
             isEnabled: Bool = true,
             showActivityIndicator: Bool = false) {
        self.showActivityIndicator = showActivityIndicator
        nameLabel.text = name
        iconImageView.image = image
        isUserInteractionEnabled = isEnabled
        
        if showActivityIndicator {
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            accessoryView = activityIndicator
            accessoryType = .none
        } else {
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
        backgroundColor = dynamicBackgroundColor
        
        if showActivityIndicator {
            nameLabel.textColor = textColor.withAlphaComponent(0.5)
            tintColor = textColor.withAlphaComponent(0.5)
        } else {
            nameLabel.textColor = textColor
            tintColor = textColor
        }
    }
    
    private var dynamicBackgroundColor: UIColor {
        TokenColors.Background.page
    }
    
    private var textColor: UIColor {
        TokenColors.Text.primary
    }
}
