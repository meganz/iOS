import MEGADesignToken
import UIKit

class EmojiReactionCollectionCell: UICollectionViewCell {
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var numberOfUsersReactedLabel: UILabel!
    @IBOutlet weak var selectedMarkerView: UIView!
    
    var displaySelectedState = true

    override var isSelected: Bool {
        didSet {
            guard displaySelectedState else {
                return
            }
            
            selectedMarkerView.isHidden = !isSelected
            updateAppearance()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selectedMarkerView.isHidden = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
        
    private func updateAppearance() {
        let color = isSelected ? TokenColors.Button.secondary : UIColor.label
        numberOfUsersReactedLabel.textColor = color
        selectedMarkerView.backgroundColor = color
    }
}
