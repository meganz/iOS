import CoreGraphics

class CondensationView: EnlargementView {    
    override func awakeFromNib() {
        super.awakeFromNib()
        enlarge = false
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        selectionView.backgroundColor = .mnz_voiceRecordingViewButtonBackground(traitCollection)
        nonSelectionView.backgroundColor = .mnz_redFF453A()
    }
}
