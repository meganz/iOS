import MEGAAssets
import MEGADesignToken
import MEGAL10n
import UIKit

protocol MessageInputBarDelegate: AnyObject {
    func tappedAddButton(_ button: UIButton)
    func tappedSendButton(withText text: String)
    func tappedVoiceButton()
    func typing(withText text: String)
    func textDidEndEditing()
    func clearEditMessage()
    func didPasteImage(_ image: UIImage)
    func messageInputBarDidExpand(_ messageInputBar: MessageInputBar)
    func messageInputBarDidCollapse(_ messageInputBar: MessageInputBar)
}

class MessageInputBar: UIView {
    
    // MARK: - Outlets
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var messageTextView: MessageTextView!
    @IBOutlet weak var messageTextViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var collapsedTextViewCoverView: UIView!
    @IBOutlet weak var expandedTextViewCoverView: UIView!
    @IBOutlet weak var semiTransparentView: UIView!

    @IBOutlet weak var messageTextViewCoverView: MessageInputTextBackgroundView!
    @IBOutlet weak var messageTextViewCoverViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewCoverViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backgroundViewTrailingTextViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundViewTrailingButtonConstraint: NSLayoutConstraint!

    @IBOutlet weak var rightButtonHolderView: UIView!
    @IBOutlet weak var rightButtonHolderViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightButtonHolderViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var expandCollapseButton: UIButton!
    @IBOutlet weak var clearEditButton: UIButton!

    @IBOutlet weak var typingIndicatorLabel: UILabel!

    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var editViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editMessageTitleLabel: MEGALabel!
    @IBOutlet weak var editViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var editMessageLabel: UILabel!
    var editMessage: ChatMessage? {
        didSet {
            configureEditField()
        }
    }

    // MARK: - Interface properties

    weak var delegate: (any MessageInputBarDelegate)?
    
    var text: String? {
        return messageTextView.text
    }
    
    var hideRightButtonHolderView: Bool = false {
        didSet {
            rightButtonHolderViewWidthConstraint.constant = hideRightButtonHolderView ? 0.0 : rightButtonHolderViewHeightConstraint.constant
            layoutIfNeeded()
        }
    }
            
    // MARK: - Private properties
    private let kMEGAUIKeyInputCarriageReturn = "\r"

    private var keyboardShowObserver: (any NSObjectProtocol)?
    private var keyboardHideObserver: (any NSObjectProtocol)?

    private var expanded: Bool = false
    private var minTopPaddingWhenExpanded: CGFloat = 20.0
    // Computes the expanded height of the messageTextView
    private var expandedHeight: CGFloat? {
        guard let editViewTopConstraintValueWhenExpanded = editViewTopConstraintValueWhenExpanded else {
            return nil
        }
        let expandedHeight = heightWhenExpanded(topConstraintValueWhenExpanded: editViewTopConstraintValueWhenExpanded)

        let minHeightRequired = rightButtonHolderView.bounds.height + expandCollapseButton.bounds.height

        return expandedHeight > minHeightRequired ? expandedHeight : heightWhenExpanded(topConstraintValueWhenExpanded: minTopPaddingWhenExpanded)
    }

    private var keyboardHeight: CGFloat?
    private let messageTextViewBottomConstraintDefaultValue: CGFloat = 15.0
    private var editViewTopConstraintValueWhenExpanded: CGFloat? {
        let minHeight = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? minTopPaddingWhenExpanded
        
        // The text view should be (statusBarHeight + 67.0) from the top of the screen
        return minHeight + 67.0
    }
    
    private let animationDuration: TimeInterval = 0.4
    private let componentsSizeCalculator = MessageInputBarComponentsSizeCalculator()
    
    // MARK: - Overriden methods.
    
    override func awakeFromNib() {
        super.awakeFromNib()

        configureImages()

        messageTextView.collapsedMaxHeightReachedAction = { [weak self] collapsedMaxHeightReached in
            guard let `self` = self, !self.expanded else {
                return
            }
            
            self.expandCollapseButton.isHidden = !collapsedMaxHeightReached
        }
        
        messageTextView.pasteAction = { [weak self] image in
            self?.delegate?.didPasteImage(image)
        }
        
        registerKeyboardNotifications()
        
        guard let messageTextViewFont = messageTextView.font else {
            fatalError("text view font does not exsists")
        }
        
        editViewHeightConstraint.constant = 0
        let inset: CGFloat = messageTextView.textContainerInset.top + messageTextView.textContainerInset.bottom
        let cover: CGFloat = messageTextViewCoverViewTopConstraint.constant + messageTextViewCoverViewBottomConstraint.constant
        messageTextViewCoverView.maxCornerRadius = messageTextViewFont.lineHeight + inset + cover
        
        calculateAddButtonBotomSpacing()
        updateAppearance()
        setSendButtonColor()
        
        backgroundColor = TokenColors.Background.page
    }
    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            if editViewHeightConstraint.constant > 0 { calculateEditViewHeight() }
            calculateAddButtonBotomSpacing()
            calculateTopEditViewSpacing()
            self.messageTextView.expandedHeight = self.expandedHeight
        }
    }
    
    // MARK: - interface method.
    
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
        
        calculateTopEditViewSpacing()

        if let typingIndicatorText = text {
            if editViewHeightConstraint.constant > 0 {
                calculateEditViewHeight()
            }
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
              let text = messageTextView.text, !text.mnz_isEmpty() else {
            return
        }
        
        messageTextView.reset()
        
        if expanded {
            expanded = false
            collapse()
        } else {
            messageTextView.invalidateIntrinsicContentSize()
        }
        
        showMicButtonUI()
        delegate.tappedSendButton(withText: text)
    }
    
    @IBAction func voiceButtonTapped(_ button: UIButton) {
        guard let delegate = delegate else {
            return
        }
        
        delegate.tappedVoiceButton()
    }
    
    @IBAction func clearEditMessage(_ sender: Any) {
        guard let delegate = delegate else {
            return
        }
        
        messageTextView.reset()
        showMicButtonUI()
        delegate.clearEditMessage()
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
    
    private func configureImages() {
        clearEditButton.setImage(MEGAAssets.UIImage.image(named: "clearEdit"), for: .normal)
        expandCollapseButton.setImage(MEGAAssets.UIImage.image(named: "expand"), for: .normal)
        micButton.setImage(MEGAAssets.UIImage.image(named: "sendVoiceClipDefault"), for: .normal)
        sendButton.setImage(MEGAAssets.UIImage.image(named: "sendButton"), for: .normal)
        sendButton.setImage(MEGAAssets.UIImage.image(named: "sendChatDisabled"), for: .disabled)
        addButton.setImage(MEGAAssets.UIImage.image(named: "navigationbar_add"), for: .normal)
    }
    
    private func heightWhenExpanded(topConstraintValueWhenExpanded: CGFloat) -> CGFloat {
        let keyboard = messageTextView.isFirstResponder ? (keyboardHeight ?? 0.0) : 0.0
        let insetHeight = topConstraintValueWhenExpanded
        + keyboard
        + editViewHeightConstraint.constant

        return UIScreen.main.bounds.height - insetHeight
    }
    
    private func configureEditField() {
        guard let editMessage = editMessage else {
            editViewHeightConstraint.constant = 0
            setSendButtonColor()
            sendButton.isEnabled = true
            
            return
        }
        calculateEditViewHeight()
        editMessageLabel.text = editMessage.message.content
        sendButton.setImage(MEGAAssets.UIImage.checkBoxSelectedSemantic, for: .normal)
        sendButton.isEnabled = !(editMessage.message.content?.isEmpty ?? true)
    }
    
    private func setSendButtonColor() {
        let image = MEGAAssets.UIImage.sendButton.withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysOriginal)
        sendButton.setImage(image, for: .normal)
    }
    
    override var keyCommands: [UIKeyCommand]? {
      return [
        UIKeyCommand(
           action: #selector(MessageInputBar.sendButtonTapped),
           input: kMEGAUIKeyInputCarriageReturn,
           discoverabilityTitle: Strings.Localizable.send
       )
      ]
    }
    
    private func updateAppearance() {
        micButton.backgroundColor = TokenColors.Background.surface1
        messageTextViewCoverView.backgroundColor = TokenColors.Background.surface1
        addButton.tintColor = TokenColors.Icon.primary
        expandedTextViewCoverView.backgroundColor = TokenColors.Background.page
        messageTextView.keyboardAppearance = traitCollection.userInterfaceStyle == .dark ? .dark : .light
    }
    
    private func registerKeyboardNotifications() {
        keyboardShowObserver = keyboardShowNotification()
        keyboardHideObserver = keyboardHideNotification()
    }
    
    private func removeKeyboardNotifications() {
        remove(observers: [keyboardShowObserver, keyboardHideObserver])
    }
    
    private func remove(observers: [(any NSObjectProtocol)?]) {
        observers.forEach { observer in
            guard let observer = observer else {
                return
            }
            
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func expand() {
        delegate?.messageInputBarDidExpand(self)
        expandAnimationStart(completionHandler: expandAnimationComplete)
    }
    
    private func collapse(_ completionHandler: (() -> Void)? = nil) {
        delegate?.messageInputBarDidCollapse(self)
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
            self.editViewTopConstraint.constant += delta
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
        
        calculateTopEditViewSpacing()
        messageTextViewBottomConstraint.constant = messageTextViewBottomConstraintDefaultValue
        expandCollapseButton.setImage(MEGAAssets.UIImage.expand, for: .normal)
    }
    
    private func expandAnimationStart(completionHandler: ((Bool) -> Void)?) {

        collapsedTextViewCoverView.isHidden = true
        messageTextViewCoverView.isHidden = true
        expandedTextViewCoverView.isHidden = false
        semiTransparentView.alpha = 0.0
        semiTransparentView.isHidden = false

        let keyboard = messageTextView.isFirstResponder ? (keyboardHeight ?? 0.0) : 0.0
        let contentHeight = [keyboard, messageTextViewBottomConstraint.constant, messageTextView.intrinsicContentSize.height, editViewHeightConstraint.constant].reduce(0, +)
        let topConstraintValue = UIScreen.main.bounds.height - contentHeight

        editViewTopConstraint.constant = topConstraintValue
        layoutIfNeeded()
        
        let bottomAnimatableConstraint = topConstraintValue
            - (editViewTopConstraintValueWhenExpanded ?? 0.0)

        UIView.animate(withDuration: animationDuration, animations: {
            self.semiTransparentView.alpha = 1.0
            self.messageTextViewBottomConstraint.constant += bottomAnimatableConstraint
            self.editViewTopConstraint.constant = self.editViewTopConstraintValueWhenExpanded ?? 0.0
            self.layoutIfNeeded()
        }, completion: completionHandler)
    }
    
    private func expandAnimationComplete(_ animationCompletion: Bool) {
        messageTextViewBottomConstraint.constant = messageTextViewBottomConstraintDefaultValue
        if let editViewTopConstraintValueWhenExpanded = editViewTopConstraintValueWhenExpanded {
            editViewTopConstraint.constant = editViewTopConstraintValueWhenExpanded
        } else {
            calculateTopEditViewSpacing()
        }
        messageTextView.expandedHeight = expandedHeight
        expandCollapseButton.setImage(MEGAAssets.UIImage.collapse, for: .normal)
    }

    private func keyboardShowNotification() -> any NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else {
                return
            }
            
            guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, self.messageTextView.isFirstResponder else {
                return
            }

            MEGALogDebug("[MessageInputBar] Keyboard did show notification triggered")

            self.keyboardHeight = keyboardFrame.size.height

            // We only update messageTextView's height when the mic button is not visible
            // (aka: when the textView is empty)
            if self.micButton.isHidden,
              let messageTextViewExpanadedHeight = self.messageTextView.expandedHeight,
                messageTextViewExpanadedHeight != self.expandedHeight {
                self.messageTextView.expandedHeight = self.expandedHeight
            }
        }
    }

    private func keyboardHideNotification() -> any NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let `self` = self else {
                return
            }

            keyboardHeight = nil

            if self.expanded {
                self.expanded = false
                self.collapse()
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
        }, completion: { _ in
            
            if self.backgroundViewTrailingTextViewConstraint.isActive {
                self.sendButton.isHidden = true
                self.sendButton.alpha = 1.0
                
                self.micButton.isHidden = false
                self.micButton.alpha = 1.0

                MEGALogDebug("[MessageInputBar] Keyboard will hide notification animation ended")
            }
        })
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
            
        }, completion: { _ in
            if self.backgroundViewTrailingButtonConstraint.isActive {
                self.micButton.isHidden = true
                self.micButton.alpha = 1.0
                
                self.sendButton.isHidden = false
                self.sendButton.alpha = 1.0
                MEGALogDebug("[MessageInputBar] Send Button UI animation completed")
            }
        })
    }
    
    private func updateTextUI() {
        delegate?.typing(withText: messageTextView.text)
        
        guard editMessage == nil else {
            sendButton.isEnabled = !messageTextView.text.isEmpty
            return
        }
        
        if messageTextView.text.isEmpty {
            showMicButtonUI()
        } else {
            showSendButtonUI()
        }
    }
    
    private func calculateEditViewHeight() {
        editViewHeightConstraint.constant = editMessageTitleLabel.sizeThatFits(CGSize(width: editMessageTitleLabel.frame.width, height: .greatestFiniteMagnitude)).height
            + editMessageLabel.sizeThatFits(CGSize(width: editMessageLabel.frame.width, height: .greatestFiniteMagnitude)).height
            + 12
    }
    
    private func calculateTopEditViewSpacing() {
        editViewTopConstraint.constant = componentsSizeCalculator.calculateTypingLabelSize(fitSize: CGSize(width: frame.width, height: .greatestFiniteMagnitude)).height + 25
    }
    
    private func calculateAddButtonBotomSpacing() {
        addButtonBottomConstraint.constant = messageTextViewBottomConstraint.constant + (componentsSizeCalculator.calculateTextViewSize(fitSize: CGSize(width: frame.width, height: .greatestFiniteMagnitude)).height - addButton.frame.height) / 2
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
