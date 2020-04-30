
class MessageTextView: UITextView {
    
    //MARK: - Properties

    var numberOfLinesBeforeScroll: UInt = 4
    var collapsedMaxHeightReachedAction: ((Bool) -> Void)?
    
    var placeholderText: String? {
        didSet {
            guard let placeholderText = placeholderText else {
                placeholderTextView.text = nil
                return
            }
            
            placeholderTextView.text = placeholderText
        }
    }
    
    //MARK: - Private properties
    
    private var textChangeNotificationToken: NSObjectProtocol!

    private var collapsedMaxHeight: CGFloat {
        guard let font = font else {
            fatalError("MessageTextView: font cannot be nil")
        }
        return CGFloat(numberOfLinesBeforeScroll) * font.lineHeight
    }
    
    private var expandedHeight: CGFloat?
    
    private lazy var placeholderTextView: UITextView = {
        let textView = UITextView()
        textView.textColor = #colorLiteral(red: 0.5176470588, green: 0.5176470588, blue: 0.5176470588, alpha: 1)
        textView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        textView.font = font
        textView.isUserInteractionEnabled = false
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    //MARK: - Overridden Properties and methods
    
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

    override func awakeFromNib() {
        super.awakeFromNib()
        
        addPlaceholderTextView()
        
        textChangeNotificationToken = NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            guard let `self` = self else {
                return
            }

            self.updatePlaceholder()
        }
    }
    
    //MARK: - Interface methods
    
    func expand(_ expanded: Bool, expandedHeight: CGFloat?) {
        self.expandedHeight = expandedHeight
        invalidateIntrinsicContentSize()
    }
    
    func set(text: String) {
        self.text = text
        updatePlaceholder()
        becomeFirstResponder()
    }
    
    //MARK: - Private methods
    
    private func updatePlaceholder() {
        self.placeholderTextView.isHidden = !self.text.isEmpty
        self.invalidateIntrinsicContentSize()
    }
    
    private func addPlaceholderTextView() {
        addSubview(placeholderTextView)
        NSLayoutConstraint.activate([
            placeholderTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholderTextView.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderTextView.topAnchor.constraint(equalTo: topAnchor),
            placeholderTextView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    //MARK: - Deinit
    
    deinit {
        NotificationCenter.default.removeObserver(textChangeNotificationToken!)
    }
}
