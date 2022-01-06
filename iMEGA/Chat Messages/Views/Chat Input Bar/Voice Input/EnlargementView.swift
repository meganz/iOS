

class EnlargementView: UIView {
    @IBOutlet weak var nonSelectionView: UIView!
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholderConstraint: NSLayoutConstraint!

    var originalWidth: CGFloat!
    var originalHeight: CGFloat!
    
    var originalPlaceholderValue: CGFloat!
    
    var tapHandler: (() -> Void)? {
        didSet {
            removeAllTapGestures()
            
            guard tapHandler != nil else {
                return
            }
            addTapGesture()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        originalWidth = widthConstraint.constant
        originalHeight = heightConstraint.constant
        originalPlaceholderValue = placeholderConstraint.constant
        updateAppearance()
    }
    
    var finalRatio: CGFloat = 0.25
    var enlarge = true

    var progress: CGFloat = 0.0 {
        didSet {
            updateUI()
        }
    }
    
    var width: CGFloat {
        let ratio = finalRatio * progress
        let extraWidth = originalWidth * ratio
        return enlarge ? originalWidth + extraWidth : originalWidth - extraWidth
    }
    
    var height: CGFloat {
        let extraHeight = (originalHeight * (finalRatio * progress))
        return enlarge ? (originalHeight + extraHeight) : (originalHeight - extraHeight)
    }
    
    var singleSideAddedWidth: CGFloat {
        let enlargeWidth = (width - originalWidth) / 2.0
        let normalWidth = (originalWidth - width) / 2.0
        return enlarge ? enlargeWidth : normalWidth
    }
    
    func updateUI() {
        widthConstraint.constant = width
        heightConstraint.constant = height

        placeholderConstraint.constant = enlarge
            ? (originalPlaceholderValue - singleSideAddedWidth)
            : (originalPlaceholderValue + singleSideAddedWidth)
        
        nonSelectionView.alpha = 1.0 - progress
        selectionView.alpha = progress
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = width / 2.0
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    private func removeAllTapGestures() {
        if let tapGestures = gestureRecognizers?.filter({ $0 is UITapGestureRecognizer }) {
            tapGestures.forEach { removeGestureRecognizer($0) }
        }
    }
    
    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    @objc func viewTapped(_ gesture: UITapGestureRecognizer) {
        guard let handler = tapHandler,
            gesture.state == .ended  else {
            return
        }
        
        handler()
    }
    
    func updateAppearance() {
        nonSelectionView.backgroundColor = .mnz_voiceRecordingViewButtonBackground(traitCollection)
        imageView.tintColor = .mnz_inputbarButtonImageTint(traitCollection)
    }

}
