

import UIKit

class MessageInputBar: UIView {
    
    @IBOutlet weak var messageTextView: MessageTextView!
    @IBOutlet weak var messageTextViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var collapsedTextViewCoverView: UIView!
    @IBOutlet weak var expandedTextViewCoverView: UIView!
    @IBOutlet weak var semiTransparentView: UIView!

    @IBOutlet weak var messageTextViewCoverView: MessageInputTextBackgroundView!
    @IBOutlet weak var messageTextViewCoverViewBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewCoverViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backgroundViewTrailingTextViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundViewTrailingButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var expandCollapseButton: UIButton!

    var keyboardShowObserver: NSObjectProtocol!
    var keyboardHideObserver: NSObjectProtocol!
    
    var expanded: Bool = false
    var expandedHeight: CGFloat? {
        guard let keyboardHeight = keyboardHeight else {
            return nil
        }
                
        return UIScreen.main.bounds.height - (messageTextViewTopConstraintValueWhenExpanded! + 15.0 + keyboardHeight)
    }
    
    var keyboardHeight: CGFloat?
    var messageTextViewToConstraintValueWhenCollapsed: CGFloat = 32.0
    var messageTextViewTopConstraintValueWhenExpanded: CGFloat? {
        var statusBarHeight: CGFloat = 20.0
        if #available(iOS 11.0, *) {
            statusBarHeight = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 20.0
        }
        
        // The text view should be (statusBarHeight + 67.0) from the top of the screen
        return statusBarHeight + 67.0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        messageTextView.collapsedMaxHeightReachedAction = { [weak self] collapsedMaxHeightReached in
            guard let `self` = self, !self.expanded else {
                return
            }
            
            self.expandCollapseButton.isHidden = !collapsedMaxHeightReached
        }
        
        registerKeyboardNotifications()
        
        messageTextViewCoverView.maxCornerRadius = messageTextView.font!.lineHeight
            + messageTextViewCoverViewTopConstraint.constant
            + messageTextViewCoverViewBottomContraint.constant
            + messageTextView.textContainerInset.top
            + messageTextView.textContainerInset.bottom
    }
    
    func registerKeyboardNotifications() {
        keyboardHideObserver = keyboardHideNotification()
        keyboardShowObserver = keyboardShowNotification()
    }
    
    func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(keyboardShowObserver!)
        NotificationCenter.default.removeObserver(keyboardHideObserver!)
    }
    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    @IBAction func exapandCollapseButtonTapped(_ button: UIButton) {
        expanded = !expanded
        /// Since we are toggling first (the above line) if toggled state is expanded we need to expand.
        if expanded {
            expand()
        } else {
            collapse()
        }
    }
    
    private func expand() {
        self.messageTextViewCoverView.isHidden = true
        self.expandedTextViewCoverView.isHidden = false
        self.collapsedTextViewCoverView.isHidden = true
        self.semiTransparentView.isHidden = false
        
        self.messageTextViewTopConstraint.constant = self.messageTextViewTopConstraintValueWhenExpanded ?? messageTextViewToConstraintValueWhenCollapsed
        self.messageTextView.expand(true, expandedHeight: self.expandedHeight)
        self.expandCollapseButton.setImage(#imageLiteral(resourceName: "collapse"), for: .normal)
        
    }
    
    private func collapse() {
        self.messageTextViewCoverView.isHidden = false
        self.expandedTextViewCoverView.isHidden = true
        self.collapsedTextViewCoverView.isHidden = false
        self.semiTransparentView.isHidden = true

        
        self.messageTextViewTopConstraint.constant = messageTextViewToConstraintValueWhenCollapsed
        self.messageTextView.expand(false, expandedHeight: nil)
        self.expandCollapseButton.setImage(#imageLiteral(resourceName: "expand"), for: .normal)
        
    }
    
    private func keyboardShowNotification() -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let `self` = self else {
                return
            }
            
            guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
            }
            
            let inputBarHeight: CGFloat = self.messageTextView.intrinsicContentSize.height
                + 15.0
                + (self.expanded ? self.messageTextViewTopConstraintValueWhenExpanded! : self.messageTextViewToConstraintValueWhenCollapsed)
            self.keyboardHeight = keyboardFrame.size.height - inputBarHeight
            
            self.backgroundViewTrailingTextViewConstraint.isActive = false
            self.backgroundViewTrailingButtonConstraint.isActive = true
            self.micButton.isHidden = true
            self.sendButton.isHidden = false
        }
    }
    
    private func keyboardHideNotification() -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            if self.messageTextView.text.count == 0 {
                UIView.animate(withDuration: 0.4) {
                    self.backgroundViewTrailingTextViewConstraint.isActive = true
                    self.backgroundViewTrailingButtonConstraint.isActive = false
                    self.micButton.isHidden = false
                    self.sendButton.isHidden = true
                }
            }
        }
    }
    
    deinit {
        removeKeyboardNotifications()
    }
}

class MessageInputTextBackgroundView: UIView {
    
    var maxCornerRadius: CGFloat = .greatestFiniteMagnitude
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.height / 2.0, maxCornerRadius)
    }
    
}
