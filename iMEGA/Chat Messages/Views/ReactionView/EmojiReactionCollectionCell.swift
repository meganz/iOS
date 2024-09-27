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
            configureColors()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureColors()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selectedMarkerView.isHidden = true
    }
    
    private func configureColors() {
        let color = isSelected ? TokenColors.Text.primary : TokenColors.Text.secondary
        numberOfUsersReactedLabel.textColor = color
        selectedMarkerView.backgroundColor = TokenColors.Background.surface3
    }
}
