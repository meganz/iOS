import CoreGraphics

class CondensationView: EnlargementView {
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var originalBottomValue: CGFloat!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        enlarge = false
        originalBottomValue = bottomConstraint.constant
    }
    
    override func updateUI() {
        super.updateUI()
        
        bottomConstraint.constant = originalBottomValue ?? CGFloat.zero + singleSideAddedWidth
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        selectionView.backgroundColor = .mnz_voiceRecordingViewButtonBackground(traitCollection)
        nonSelectionView.backgroundColor = .mnz_redFF453A()
    }
}
