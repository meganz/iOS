
import UIKit

class EmojiCollectionCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var selectedMarkerView: UIView!
    @IBOutlet weak var emojiBackgroundView: UIView!
    
    var displaySelectedState = true

    override var isSelected: Bool {
        didSet {
            guard displaySelectedState else {
                return
            }
            
            selectedMarkerView.isHidden = !isSelected
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selectedMarkerView.isHidden = true
        emojiBackgroundView.isHidden = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !emojiBackgroundView.isHidden else {
            return
        }
        
        emojiBackgroundView.layer.cornerRadius = emojiBackgroundView.bounds.width / 2.0
    }
    
    private func updateAppearance() {
        if #available(iOS 13.0, *) {
            emojiBackgroundView.backgroundColor = UIColor.darkText.withAlphaComponent(0.5)
        } else {
            emojiBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }
}
