import MEGAAssets
import MEGAL10n
import UIKit

class AddToChatAllowAccessCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var allowAccessTextLabel: UILabel!
    @IBOutlet weak var allowAccessImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        MainActor.assumeIsolated {
            allowAccessTextLabel.text = Strings.Localizable.Chat.Photos.allowPhotoAccessMessage
            allowAccessImageView.image = MEGAAssets.UIImage.image(named: "Allow Acess")
            updateAppearance()
            registerForAppearanceChanges()
        }
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) { (cell: AddToChatAllowAccessCollectionCell, _: UITraitCollection) in
            cell.updateAppearance()
        }
    }

    private func updateAppearance() {
        allowAccessTextLabel.textColor = .mnz_toolbarTextColor(traitCollection)
    }
}
