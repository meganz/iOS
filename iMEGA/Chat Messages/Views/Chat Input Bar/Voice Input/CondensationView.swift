import CoreGraphics
import MEGADesignToken

class CondensationView: EnlargementView {    
    override func awakeFromNib() {
        super.awakeFromNib()
        enlarge = false
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        selectionView.backgroundColor = TokenColors.Icon.secondary
        nonSelectionView.backgroundColor = TokenColors.Components.interactive
    }
}
