

import UIKit

class MessageInputBar: UIView {
    @IBOutlet weak var backgroundView: MessageInputTextBackgroundView!
    @IBOutlet weak var messageTextView: MessageTextView!
    @IBOutlet weak var backgroundViewBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backgroundViewTrailingTextViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundViewTrailingButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var expandCollapseButton: UIButton!

    var keyboardShowObserver: NSObjectProtocol!
    var keyboardHideObserver: NSObjectProtocol!
    
    var expanded: Bool = false
    var expandedHeight: CGFloat?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        messageTextView.collapsedMaxHeightReachedAction = { [weak self] collapsedMaxHeightReached in
            guard let `self` = self, !self.expanded else {
                return
            }
            
            self.expandCollapseButton.isHidden = !collapsedMaxHeightReached
        }
        
        registerKeyboardNotifications()
        
        backgroundView.maxCornerRadius = messageTextView.font!.lineHeight
            + backgroundViewTopConstraint.constant
            + backgroundViewBottomContraint.constant
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
//        UIView.animate(withDuration: 0.4) {
            self.backgroundView.isHidden = true
            self.messageTextView.expand(true, expandedHeight: self.expandedHeight)
            self.expandCollapseButton.setImage(#imageLiteral(resourceName: "collapse"), for: .normal)
//            self.setNeedsLayout()
//            self.layoutIfNeeded()
//        }
    }
    
    private func collapse() {
//        UIView.animate(withDuration: 0.4) {
            self.backgroundView.isHidden = false
            self.messageTextView.expand(false, expandedHeight: nil)
            self.expandCollapseButton.setImage(#imageLiteral(resourceName: "expand"), for: .normal)
//            self.setNeedsLayout()
//            self.layoutIfNeeded()
//        }
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
            
            self.expandedHeight = UIScreen.main.bounds.height - keyboardFrame.size.height - 64
            
//            UIView.animate(withDuration: 0.4) {
                self.backgroundViewTrailingTextViewConstraint.isActive = false
                self.backgroundViewTrailingButtonConstraint.isActive = true
                self.micButton.isHidden = true
                self.sendButton.isHidden = false
//            }
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
