import MEGADesignToken
import MEGAPresentation
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
            let activityIndicator = UIActivityIndicatorView.mnz_init()
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
    
    private var designTokenEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
    }
    
    private var dynamicBackgroundColor: UIColor {
        if designTokenEnabled {
            TokenColors.Background.page
        } else {
            UIColor.cellBackground
        }
    }
    
    private var textColor: UIColor {
        if designTokenEnabled {
            TokenColors.Text.primary
        } else {
            UIColor.label
        }
    }
}
