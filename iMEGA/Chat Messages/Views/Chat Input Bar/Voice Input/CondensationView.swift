import CoreGraphics
import MEGADesignToken

class CondensationView: EnlargementView {    
    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            enlarge = false
        }
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        selectionView.backgroundColor = TokenColors.Icon.secondary
        nonSelectionView.backgroundColor = TokenColors.Components.interactive
    }
}
