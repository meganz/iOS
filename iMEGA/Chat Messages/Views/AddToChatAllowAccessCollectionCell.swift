
import UIKit

class AddToChatAllowAccessCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var allowAccessTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        allowAccessTextLabel.text = AMLocalizedString("To share photos and videos allow MEGA to access your gallery")
        updateAppearance()
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
        }
    }
    
    private func updateAppearance() {
        allowAccessTextLabel.textColor = .mnz_toolbarTextColor(traitCollection)
    }
}
