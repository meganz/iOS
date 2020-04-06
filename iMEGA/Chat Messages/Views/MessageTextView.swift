
class MessageTextView: UITextView {
    
    var textChangeNotificationToken: NSObjectProtocol!
    var numberOfLinesBeforeScroll: UInt = 4
    
    var collapsedMaxHeightReachedAction: ((Bool) -> Void)?
    
    private var collapsedMaxHeight: CGFloat {
        guard let font = font else {
            fatalError("MessageTextView: font cannot be nil")
        }
        return CGFloat(numberOfLinesBeforeScroll) * font.lineHeight
    }
    
    private var expandedHeight: CGFloat?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textChangeNotificationToken = NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        
        if let expandedHeight = expandedHeight {
            size.height = expandedHeight
        } else {
            if size.height == UIView.noIntrinsicMetric {
                size.height = layoutManager.usedRect(for: textContainer).height
                    + textContainerInset.top
                    + textContainerInset.bottom
            }
            
            if size.height > collapsedMaxHeight {
                size.height = collapsedMaxHeight
            }
        }
        
        if let action = collapsedMaxHeightReachedAction {
            action(size.height == collapsedMaxHeight)
        }
        
        return size
    }
    
    func expand(_ expanded: Bool, expandedHeight: CGFloat?) {
        self.expandedHeight = expandedHeight
        self.invalidateIntrinsicContentSize()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(textChangeNotificationToken!)
    }
}
