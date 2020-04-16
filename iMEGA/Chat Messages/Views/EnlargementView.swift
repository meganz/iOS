

class EnlargementView: UIView {
    @IBOutlet weak var nonSelectionView: UIView!
    @IBOutlet weak var selectionView: UIView!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholderConstraint: NSLayoutConstraint!

    var originalWidth: CGFloat!
    var originalHeight: CGFloat!
    
    var originalPlaceholderValue: CGFloat!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        originalWidth = widthConstraint.constant
        originalHeight = heightConstraint.constant
        originalPlaceholderValue = placeholderConstraint.constant
    }
    
    var finalRatio: CGFloat = 0.25
    var enlarge = true

    var progress: CGFloat = 0.0 {
        didSet {
            updateUI()
        }
    }
    
    var width: CGFloat {
        let extraWidth = (originalWidth * (finalRatio * progress))
        return enlarge ? (originalWidth + extraWidth) : (originalWidth - extraWidth)
    }
    
    var height: CGFloat {
        let extraHeight = (originalHeight * (finalRatio * progress))
        return enlarge ? (originalHeight + extraHeight) : (originalHeight - extraHeight)
    }
    
    var singleSideAddedWidth: CGFloat {
        return enlarge ? ((width - originalWidth) / 2.0) : ((originalWidth - width) / 2.0)
    }
    
    func updateUI() {
        widthConstraint.constant = width
        heightConstraint.constant = height

        placeholderConstraint.constant = enlarge
            ? (originalPlaceholderValue - singleSideAddedWidth)
            : (originalPlaceholderValue + singleSideAddedWidth)
        
        nonSelectionView.alpha = 1.0 - progress
        selectionView.alpha = progress
        
        layer.cornerRadius = width / 2.0
    }
}
