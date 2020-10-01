

import UIKit

protocol MessageInputBarDelegate: class {
    func tappedAddButton(_ button: UIButton)
    func tappedSendButton(withText text: String)
    func tappedVoiceButton()
    func typing(withText text: String)
    func textDidEndEditing()
}

class MessageInputBar: UIView {
    
    // MARK:- Outlets
    @IBOutlet weak var addButton: UIButton!

    @IBOutlet weak var messageTextView: MessageTextView!
    @IBOutlet weak var messageTextViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var collapsedTextViewCoverView: UIView!
    @IBOutlet weak var expandedTextViewCoverView: UIView!
    @IBOutlet weak var semiTransparentView: UIView!

    @IBOutlet weak var messageTextViewCoverView: MessageInputTextBackgroundView!
    @IBOutlet weak var messageTextViewCoverViewBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewCoverViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backgroundViewTrailingTextViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundViewTrailingButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var rightButtonHolderView: UIView!
    @IBOutlet weak var rightButtonHolderViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightButtonHolderViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var expandCollapseButton: UIButton!
    
    @IBOutlet weak var typingIndicatorLabel: UILabel!

    
    // MARK:- Interface properties

    weak var delegate: MessageInputBarDelegate?
    
    var text: String? {
        return messageTextView.text
    }
    
    var hideRightButtonHolderView: Bool = false {
        didSet {
            rightButtonHolderViewWidthConstraint.constant = hideRightButtonHolderView ? 0.0 : rightButtonHolderViewHeightConstraint.constant
            layoutIfNeeded()
        }
    }
            
    // MARK:- Private properties
    private let kMEGAUIKeyInputCarriageReturn = "\r"

    private var keyboardWillShowObserver: NSObjectProtocol?
    private var keyboardShowObserver: NSObjectProtocol?
    private var keyboardHideObserver: NSObjectProtocol?
    
    private var expanded: Bool = false
    private var minTopPaddingWhenExpanded: CGFloat = 20.0
    private var expandedHeight: CGFloat? {
        guard let messageTextViewTopConstraintValueWhenExpanded = messageTextViewTopConstraintValueWhenExpanded else {
            return nil
        }
        
        let expandedHeight = heightWhenExpanded(topConstraintValueWhenExpanded: messageTextViewTopConstraintValueWhenExpanded)
        let minHeightRequired = rightButtonHolderView.bounds.height + expandCollapseButton.bounds.height
        return expandedHeight > minHeightRequired ? expandedHeight :  heightWhenExpanded(topConstraintValueWhenExpanded: minTopPaddingWhenExpanded)
    }
    
    private func heightWhenExpanded(topConstraintValueWhenExpanded: CGFloat) -> CGFloat {
        return UIScreen.main.bounds.height -
            (topConstraintValueWhenExpanded
                + messageTextViewBottomConstraintDefaultValue
                + (messageTextView.isFirstResponder ? (keyboardHeight ?? 0.0) : 0.0))
    }

    private var keyboardHeight: CGFloat?
    private let messageTextViewBottomConstraintDefaultValue: CGFloat = 15.0
    private let messageTextViewTopConstraintValueWhenCollapsed: CGFloat = 32.0
    private var messageTextViewTopConstraintValueWhenExpanded: CGFloat? {
        var minHeight = minTopPaddingWhenExpanded
        if #available(iOS 11.0, *) {
            minHeight = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? minTopPaddingWhenExpanded
        }
        
        // The text view should be (statusBarHeight + 67.0) from the top of the screen
        return minHeight + 67.0
    }
    
    private let animationDuration: TimeInterval = 0.4
    
    // MARK: - Overriden methods.
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        messageTextView.collapsedMaxHeightReachedAction = { [weak self] collapsedMaxHeightReached in
            guard let `self` = self, !self.expanded else {
                return
            }
            
            self.expandCollapseButton.isHidden = !collapsedMaxHeightReached
        }
        
        registerKeyboardNotifications()
        
        guard let messageTextViewFont = messageTextView.font else {
            fatalError("text view font does not exsists")
        }
        
        messageTextViewCoverView.maxCornerRadius = messageTextViewFont.lineHeight
            + messageTextViewCoverViewTopConstraint.constant
            + messageTextViewCoverViewBottomContraint.constant
            + messageTextView.textContainerInset.top
            + messageTextView.textContainerInset.bottom
        
        updateAppearance()
    }
    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
        }
    }
    
    //MARK: - interface method.
    
    func isMicButtonPresent(atLocation point: CGPoint) -> Bool {
        let view = hitTest(point, with: nil)
        return view === micButton
    }
    
    func dismissKeyboard() {
        messageTextView.resignFirstResponder()
    }
    
    func set(text: String, showKeyboard: Bool) {
        messageTextView.set(text: text, showKeyboard: showKeyboard)
        updateTextUI()
        if !text.isEmpty {
            showSendButtonUI()
        }
    }
    
    func set(keyboardAppearance: UIKeyboardAppearance) {
        messageTextView.set(keyboardAppearance: keyboardAppearance)
    }
    
    func setTypingIndicator(text: NSAttributedString?) {
        typingIndicatorLabel.isHidden = (text == nil)

        if let typingIndicatorText = text {
            typingIndicatorLabel.attributedText = typingIndicatorText
        }
    }
    
    func isTextViewTheFirstResponder() -> Bool {
        return messageTextView.isFirstResponder
    }
    
    func relayout() {
        if expanded {
            messageTextView.expandedHeight = expandedHeight
        }
        
        invalidateIntrinsicContentSize()
        messageTextView.relayout()
    }
    
    // MARK: - Actions
    
    @IBAction func exapandCollapseButtonTapped(_ button: UIButton) {
        expanded = !expanded
        /// Since we are toggling first (the above line) if toggled state is expanded we need to expand.
        if expanded {
            expand()
        } else {
            collapse()
        }
    }
    
    @IBAction func sendButtonTapped(_ button: UIButton) {
        guard let delegate = delegate,
              let text = messageTextView.text, !text.isEmpty else {
            return
        }
        
        messageTextView.reset()
        
        if expanded {
            expanded = false
            collapse()
        } else {
            messageTextView.invalidateIntrinsicContentSize()
        }
        
        sendButton.isEnabled = false
        
        if !messageTextView.isFirstResponder {
            showMicButtonUI()
        }
        
        delegate.tappedSendButton(withText: text)
    }
    
    @IBAction func voiceButtonTapped(_ button: UIButton) {
        guard let delegate = delegate else {
            return
        }
        
        delegate.tappedVoiceButton()
    }
    
    @IBAction func addButtonTapped(_ button: UIButton) {
        guard let delegate = delegate else {
            return
        }
        
        if expanded {
            collapse {
                delegate.tappedAddButton(button)
            }
        } else {
            delegate.tappedAddButton(button)
        }
        
    }
    
    // MARK: - Private methods
    
    override var keyCommands: [UIKeyCommand]? {
      return [
        UIKeyCommand(input: kMEGAUIKeyInputCarriageReturn,
          modifierFlags: [],
          action: #selector(MessageInputBar.sendButtonTapped),
          discoverabilityTitle: AMLocalizedString("send"))
      ]
    }
    
    private func updateAppearance() {
        micButton.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        messageTextViewCoverView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        addButton.tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        expandedTextViewCoverView.backgroundColor = UIColor.mnz_backgroundElevated(traitCollection)
        if #available(iOS 12.0, *) {
            messageTextView.keyboardAppearance = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        }
    }
    
    private func registerKeyboardNotifications() {
        keyboardHideObserver = keyboardHideNotification()
        keyboardShowObserver = keyboardShowNotification()
        keyboardWillShowObserver = keyboardWillShowNotification()
    }
    
    private func removeKeyboardNotifications() {
        remove(observer: keyboardWillShowObserver)
        remove(observer: keyboardShowObserver)
        remove(observer: keyboardHideObserver)
    }
    
    private func remove(observer: NSObjectProtocol?) {
        guard let observer = observer else {
            return
        }
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    private func expand() {
        expandAnimationStart(completionHandler: expandAnimationComplete)
    }
    
    private func collapse(_ completionHandler: (() -> Void)? = nil) {
        collapseAnimationStart { _ in
            self.collapseAnimationComplete()
            completionHandler?()
        }
    }
    
    private func collapseAnimationStart(completionHandler: ((Bool) -> Void)?) {
        messageTextViewCoverView.isHidden = false
        messageTextViewCoverView.alpha = 0.0
        
        let priorValue = messageTextView.intrinsicContentSize.height
        messageTextView.expandedHeight = nil
        let newValue = messageTextView.intrinsicContentSize.height
        let delta = priorValue - newValue
        messageTextViewBottomConstraint.constant += delta
        layoutIfNeeded()
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.messageTextViewBottomConstraint.constant = self.messageTextViewBottomConstraintDefaultValue
            self.messageTextViewTopConstraint.constant += delta
            self.messageTextViewCoverView.alpha = 1.0
            self.semiTransparentView.alpha = 0.0
            self.layoutIfNeeded()
        }, completion: completionHandler)
    }
    
    private func collapseAnimationComplete() {
        expandedTextViewCoverView.isHidden = true
        collapsedTextViewCoverView.isHidden = false

        semiTransparentView.isHidden = true
        semiTransparentView.alpha = 1.0
        
        messageTextViewTopConstraint.constant = messageTextViewTopConstraintValueWhenCollapsed
        messageTextViewBottomConstraint.constant = messageTextViewBottomConstraintDefaultValue
        expandCollapseButton.setImage(#imageLiteral(resourceName: "expand"), for: .normal)
    }
    
    private func expandAnimationStart(completionHandler: ((Bool) -> Void)?) {
        collapsedTextViewCoverView.isHidden = true
        messageTextViewCoverView.isHidden = true
        expandedTextViewCoverView.isHidden = false
        semiTransparentView.alpha = 0.0
        semiTransparentView.isHidden = false

        let topConstraintValue: CGFloat = UIScreen.main.bounds.height
            - ((messageTextView.isFirstResponder ? (keyboardHeight ?? 0.0) : 0.0)
                + messageTextViewBottomConstraint.constant
                + messageTextView.intrinsicContentSize.height)

        messageTextViewTopConstraint.constant = topConstraintValue
        layoutIfNeeded()
        
        let bottomAnimatableConstraint = topConstraintValue
            - (messageTextViewTopConstraintValueWhenExpanded ?? 0.0)

        UIView.animate(withDuration: animationDuration, animations: {
            self.semiTransparentView.alpha = 1.0
            self.messageTextViewBottomConstraint.constant += bottomAnimatableConstraint
            self.messageTextViewTopConstraint.constant = self.messageTextViewTopConstraintValueWhenExpanded ?? 0.0
            self.layoutIfNeeded()
        }, completion: completionHandler)
    }
    
    private func expandAnimationComplete(_ animationCompletion: Bool) {
        messageTextViewBottomConstraint.constant = messageTextViewBottomConstraintDefaultValue
        messageTextViewTopConstraint.constant = messageTextViewTopConstraintValueWhenExpanded ?? messageTextViewTopConstraintValueWhenCollapsed
        messageTextView.expandedHeight = expandedHeight
        expandCollapseButton.setImage(#imageLiteral(resourceName: "collapse"), for: .normal)
    }
    
    private func keyboardWillShowNotification() -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let `self` = self,
                  self.messageTextView.isFirstResponder else {
                return
            }
            
            self.showSendButtonUI()
        }
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
            
            guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, self.messageTextView.isFirstResponder else {
                return
            }
            
            MEGALogDebug("[MessageInputBar] Keyboard did show notification triggered")

            let inputBarHeight: CGFloat = self.messageTextView.intrinsicContentSize.height
                + self.messageTextViewBottomConstraint.constant
                + self.messageTextViewTopConstraint.constant
            self.keyboardHeight = keyboardFrame.size.height - inputBarHeight
            
            if self.backgroundViewTrailingButtonConstraint.isActive,
                let messageTextViewExpanadedHeight = self.messageTextView.expandedHeight,
                messageTextViewExpanadedHeight != self.expandedHeight {
                self.messageTextView.expandedHeight = self.expandedHeight
            }
            
            if self.messageTextView.isFirstResponder && !self.backgroundViewTrailingButtonConstraint.isActive {
                
                self.micButton.isHidden = true
                self.micButton.alpha = 1.0
                
                self.sendButton.isHidden = false
                self.sendButton.alpha = 1.0
                
                self.backgroundViewTrailingTextViewConstraint.isActive = false
                self.backgroundViewTrailingButtonConstraint.isActive = true
                self.layoutIfNeeded()
            }
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
                        
            MEGALogDebug("[MessageInputBar] Keyboard will hide notification triggered")

            if self.messageTextView.text.isEmpty {
                self.showMicButtonUI()
            }
        }
    }
    
    private func showMicButtonUI() {
        micButton.alpha = 0.0
        micButton.isHidden = false

        UIView.animate(withDuration: self.animationDuration, animations: {
            self.backgroundViewTrailingButtonConstraint.isActive = false
            self.backgroundViewTrailingTextViewConstraint.isActive = true
            self.micButton.alpha = 1.0
            self.sendButton.alpha = 0.0
            self.layoutIfNeeded()
            MEGALogDebug("[MessageInputBar] Keyboard will hide notification animation started")
        }) { _ in
            
            if self.backgroundViewTrailingTextViewConstraint.isActive  {
                self.sendButton.isHidden = true
                self.sendButton.alpha = 1.0
                
                self.micButton.isHidden = false
                self.micButton.alpha = 1.0

                MEGALogDebug("[MessageInputBar] Keyboard will hide notification animation ended")
            }
        }
    }
    
    private func showSendButtonUI() {
        if backgroundViewTrailingButtonConstraint.isActive {
            MEGALogDebug("[MessageInputBar] textview is not the first responder or the backgroundViewTrailingButtonConstraint is active")
            return
        }
        
        sendButton.alpha = 0.0
        sendButton.isHidden = false
        MEGALogDebug("[MessageInputBar] Send Button UI triggered")
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.backgroundViewTrailingTextViewConstraint.isActive = false
            self.backgroundViewTrailingButtonConstraint.isActive = true
            self.micButton.alpha = 0.0
            self.sendButton.alpha = 1.0
            self.layoutIfNeeded()
            MEGALogDebug("[MessageInputBar] Send Button UI animation started")
            
        }) { _ in
            if self.backgroundViewTrailingButtonConstraint.isActive {
                self.micButton.isHidden = true
                self.micButton.alpha = 1.0
                
                self.sendButton.isHidden = false
                self.sendButton.alpha = 1.0
                MEGALogDebug("[MessageInputBar] Send Button UI animation completed")
            }
        }
    }
    
    private func updateTextUI() {
        guard let delegate = delegate,
            let text = messageTextView.text else {
            return
        }
        
        sendButton.isEnabled = !(text as NSString).mnz_isEmpty()
        delegate.typing(withText: text)
    }
    
    
    // MARK: - Deinit
    
    deinit {
        removeKeyboardNotifications()
    }
}

// MARK: - UITextViewDelegate

extension MessageInputBar: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateTextUI()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textDidEndEditing()
    }
}


