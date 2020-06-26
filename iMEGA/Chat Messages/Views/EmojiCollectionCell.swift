
import UIKit

class EmojiCollectionCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var selectedMarkerView: UIView!

    override var isSelected: Bool {
        didSet {
            selectedMarkerView.isHidden = !isSelected
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selectedMarkerView.isHidden = true
    }

}
