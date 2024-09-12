import MEGADesignToken
import MEGAL10n

class MessageTextView: UITextView {
    
    // MARK: - Properties

    var numberOfLinesBeforeScroll: UInt = 4
    var collapsedMaxHeightReachedAction: ((Bool) -> Void)?
    var pasteAction: ((UIImage) -> Void)?
    
    lazy var lineIntrinsicContentSize: CGFloat = {
        (font?.lineHeight ?? 21.0) + textContainerInset.top + textContainerInset.bottom
    }()
    
    var placeholderText: String? {
        didSet {
            guard let placeholderText = placeholderText else {
                placeholderTextView.text = nil
                return
            }
            
            placeholderTextView.text = placeholderText
        }
    }
    
    var expandedHeight: CGFloat? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    // MARK: - Private properties
    
    private var textChangeNotificationToken: (any NSObjectProtocol)?

    private var collapsedMaxHeight: CGFloat {
        guard let font = font else {
            fatalError("MessageTextView: font cannot be nil")
        }
        return CGFloat(numberOfLinesBeforeScroll) * font.lineHeight
    }
    
    private lazy var placeholderTextView: UITextView = {
        let textView = UITextView()
        textView.textColor = TokenColors.Text.placeholder
        textView.backgroundColor = UIColor.black000000.withAlphaComponent(0)
        textView.font = font
        textView.adjustsFontForContentSizeCategory = true
        textView.isUserInteractionEnabled = false
        textView.isScrollEnabled = false
        textView.text = Strings.Localizable.Chat.Message.placeholder

        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    // MARK: - Overridden Properties and methods

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
        updateAppearance()
        
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    // MARK: - Interface methods
    
    func set(text: String, showKeyboard: Bool) {
        self.text = text
        updatePlaceholder()
        
        if showKeyboard {
            becomeFirstResponder()
        }
    }
    
    func set(keyboardAppearance: UIKeyboardAppearance) {
        self.keyboardAppearance = keyboardAppearance
        reloadInputViews()
    }
    
    func reset() {
        self.text = nil
        updatePlaceholder()
    }
    
    func relayout() {
        invalidateIntrinsicContentSize()
    }
    
    // MARK: - Private methods
    
    private func updateAppearance() {
        tintColor = TokenColors.Icon.accent
        placeholderTextView.textColor = TokenColors.Text.placeholder
    }
    
    private func updatePlaceholder() {
        placeholderTextView.isHidden = !text.isEmpty
        invalidateIntrinsicContentSize()
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
    
    // MARK: - Image Paste Support
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        if action == NSSelectorFromString("paste:") && UIPasteboard.general.loadImage() != nil {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    open override func paste(_ sender: Any?) {
        
        guard let image = UIPasteboard.general.loadImage() else {
            return super.paste(sender)
        }
        pasteAction?(image)
    }
    
    // MARK: - Deinit
    
    deinit {
        NotificationCenter.default.removeObserver(textChangeNotificationToken!)
    }
}
