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
        nonSelectionView.backgroundColor = TokenColors.Components.interactive
    }
}
