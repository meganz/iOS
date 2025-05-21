import MEGAAssets
import MEGAL10n
import UIKit

class AddToChatAllowAccessCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var allowAccessTextLabel: UILabel!
    @IBOutlet weak var allowAccessImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        allowAccessTextLabel.text = Strings.Localizable.Chat.Photos.allowPhotoAccessMessage
        allowAccessImageView.image = MEGAAssets.UIImage.image(named: "Allow Acess")
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
