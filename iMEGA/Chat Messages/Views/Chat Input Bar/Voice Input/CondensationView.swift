
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
        
        bottomConstraint.constant = originalBottomValue + singleSideAddedWidth
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        selectionView.backgroundColor = UIColor.mnz_secondaryButtonBackground(for: traitCollection)
        nonSelectionView.backgroundColor = UIColor.mnz_redFF453A()
    }
}
