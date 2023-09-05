import MEGAL10n
import UIKit

class AddToChatAllowAccessCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var allowAccessTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        allowAccessTextLabel.text = Strings.Localizable.Chat.Photos.allowPhotoAccessMessage

        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        allowAccessTextLabel.textColor = .mnz_toolbarTextColor(traitCollection)
    }
}
