import CoreGraphics
import MEGADesignToken

class CondensationView: EnlargementView {    
    override func awakeFromNib() {
        super.awakeFromNib()
        enlarge = false
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        selectionView.backgroundColor = .mnz_voiceRecordingViewButtonBackground(traitCollection)
        if UIColor.isDesignTokenEnabled() {
            nonSelectionView.backgroundColor = TokenColors.Components.interactive
        } else {
            nonSelectionView.backgroundColor = .mnz_redFF453A()
        }
    }
}
