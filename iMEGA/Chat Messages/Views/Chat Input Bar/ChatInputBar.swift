import simd
import UIKit

protocol ChatInputBarDelegate: MessageInputBarDelegate {
    func tappedSendAudio(atPath path: String)
    func showTapAndHoldMessage()
    func voiceRecordingStarted()
    func voiceRecordingEnded()
    func clearEditMessage()
    func didPasteImage(_ image: UIImage)
    var canRecordAudio: Bool { get }
    func requestOrInformAudioPermissions()
    var existsActiveCall: Bool { get }
    func presentActiveCall()
}

class ChatInputBar: UIView {

    // MARK: - Gestures properties

    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        recognizer.minimumPressDuration = 0.4
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = false
        return recognizer
    }()
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = false
        return recognizer
    }()
    
    private lazy var fingerLiftupGesture: FingerLiftupGestureRecognizer = {
        let recognizer = FingerLiftupGestureRecognizer(target: self, action: #selector(fingerLiftUpDetected))
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        return recognizer
    }()
    
    // MARK: - Private properties

    private let messageInputBar = MessageInputBar.instanceFromNib
    private var audioRecordingInputBar: AudioRecordingInputBar?
    private var voiceClipInputBar: VoiceClipInputBar?
    private var initialTranslation: SIMD2<Double>?
    private var storedMessageInputBarHeight: CGFloat = 0.0
    private var animationDuration: TimeInterval = 0.4
    private var voiceClipInputBarRegularHeight: CGFloat = 320.0
    private var keyboardFrameChangeObserver: (any NSObjectProtocol)?

    // MARK: - Interface properties

    weak var delegate: (any ChatInputBarDelegate)?
    var editMessage: ChatMessage? {
        didSet {
            messageInputBar.editMessage = editMessage
        }
    }
    var voiceRecordingViewCanBeDismissed = false

    var voiceRecordingViewEnabled: Bool = false {
        didSet {
            messageInputBar.hideRightButtonHolderView = voiceRecordingViewEnabled
            
            if voiceRecordingViewEnabled {
                constraints
                    .filter({ $0.firstAttribute == .bottom && $0.firstItem === messageInputBar })
                    .forEach { $0.isActive = false }
                constraints
                    .filter({ $0.firstAttribute == .top && $0.firstItem === messageInputBar })
                    .forEach { $0.isActive = false }
                
                messageInputBar.messageTextView.isScrollEnabled = false
                messageInputBar.expandCollapseButton.isHidden = true

                let voiceClipInputBar = VoiceClipInputBar.instanceFromNib
                voiceClipInputBar.delegate = self
                
                self.wrap(voiceClipInputBar, excludeConstraints: [.top])
               
                let voiceClipInputBarHeight = (traitCollection.verticalSizeClass == .compact) ? voiceClipInputBarRegularHeight - 100: voiceClipInputBarRegularHeight
                let voiceClipInputBarHeightConstraint = voiceClipInputBar.heightAnchor.constraint(equalToConstant: 0)
                voiceClipInputBarHeightConstraint.isActive = true
                
                voiceClipInputBar.topAnchor.constraint(equalTo: messageInputBar.bottomAnchor).isActive = true
                
                layoutIfNeeded()
                
                self.voiceClipInputBar = voiceClipInputBar
                
                UIView.animate(withDuration: animationDuration, animations: {
                    voiceClipInputBarHeightConstraint.constant = voiceClipInputBarHeight
                    self.layoutIfNeeded()
                }, completion: { _ in
                    self.messageInputBar.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
                    self.layoutIfNeeded()
                    self.invalidateIntrinsicContentSize()
                    self.voiceRecordingViewCanBeDismissed = true
                })
            } else {
                voiceRecordingViewCanBeDismissed = false
                
                guard
                    let voiceClipInputBar,
                    let voiceClipInputBarHeightConstraint = voiceClipInputBar.constraints.first(where: { $0.firstAttribute == .height })
                else {
                    return
                }
                
                voiceClipInputBar.startRecordingView.isHidden = true
                voiceClipInputBar.trashView.isHidden = true
                voiceClipInputBar.sendView.isHidden = true
                
                UIView.animate(withDuration: animationDuration, animations: {
                    voiceClipInputBarHeightConstraint.constant = 0.0
                    self.layoutIfNeeded()
                }, completion: { _ in
                    
                    self.messageInputBar.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

                    voiceClipInputBar.startRecordingView.isHidden = false
                    voiceClipInputBar.trashView.isHidden = false
                    voiceClipInputBar.sendView.isHidden = false

                    voiceClipInputBar.cancelRecordingIfNeeded()
                    voiceClipInputBar.removeFromSuperview()
                    self.voiceClipInputBar = nil
                    
                    self.messageInputBar.messageTextView.isScrollEnabled = true
                    self.messageInputBar.expandCollapseButton.isHidden = false
                    
                    self.layoutIfNeeded()
                    self.invalidateIntrinsicContentSize()
                })
            }
        }
    }
    
    var text: String? {
        return messageInputBar.text
    }

    // MARK: - overriden properties and methods

    override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    // observation: By default the returned left and right safe area insets (super) are wrong when orientation is changed from portrait to landscape and back to portrait. Hence taking it from window.
    override var safeAreaInsets: UIEdgeInsets {
        if let window = window {
            let edgeInsets = super.safeAreaInsets
            return UIEdgeInsets(top: edgeInsets.top, left: window.safeAreaInsets.left, bottom: edgeInsets.bottom, right: window.safeAreaInsets.right)
        } else { }
        return .zero
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addGestureRecognizer(longPressGesture)
        addGestureRecognizer(panGesture)
        addGestureRecognizer(fingerLiftupGesture)
        
        addMessageInputBar()
        keyboardFrameChangeObserver = keyboardFrameChangedNotification()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if let previousTraitCollection = previousTraitCollection,
            traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass
                || traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass {
            
            if let voiceClipInputBar = voiceClipInputBar,
                voiceClipInputBar.superview != nil,
                let voiceClipInputBarHeightConstraint = voiceClipInputBar.constraints.first(where: { $0.firstAttribute == .height }) {
                voiceClipInputBarHeightConstraint.constant = (traitCollection.verticalSizeClass == .compact) ? voiceClipInputBarRegularHeight - 100: voiceClipInputBarRegularHeight
            }
        }
    }
    
    deinit {
        guard let keyboardFrameChangeObserver = keyboardFrameChangeObserver else {
            return
        }
        
        NotificationCenter.default.removeObserver(keyboardFrameChangeObserver)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dismissKeyboard() {
        messageInputBar.dismissKeyboard()
    }
    
    func isTextViewTheFirstResponder() -> Bool {
        return messageInputBar.isTextViewTheFirstResponder()
    }

    // MARK: - Interface methods.
    
    func set(text: String, showKeyboard: Bool = true) {
        guard messageInputBar.superview != nil else {
            fatalError("message input bar was not the shown to the user")
        }
        
        messageInputBar.set(text: text, showKeyboard: showKeyboard)
    }
    
    func set(keyboardAppearance: UIKeyboardAppearance) {
        guard messageInputBar.superview != nil else {
            return
        }
        
        messageInputBar.set(keyboardAppearance: keyboardAppearance)
    }
    
    func setTypingIndicator(text: NSAttributedString?) {
        guard messageInputBar.superview != nil else {
            MEGALogInfo("message input bar was not the shown to the user")
            return
        }
        
        messageInputBar.setTypingIndicator(text: text)
    }
    
    func relayout() {
        invalidateIntrinsicContentSize()
        guard messageInputBar.superview != nil else {
            MEGALogInfo("message input bar was not the shown to the user")
            return
        }
        
        messageInputBar.relayout()
    }

    // MARK: - Private methods.
    
    private func addMessageInputBar() {
        if messageInputBar.superview != nil {
            messageInputBar.removeFromSuperview()
        }
        
        messageInputBar.delegate = self
        
        addSubview(messageInputBar)
        messageInputBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            messageInputBar.topAnchor.constraint(equalTo: topAnchor),
            messageInputBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageInputBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageInputBar.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func voiceInputBarToTextInputSwitch(completionBlock: (() -> Void)? = nil) {
        guard let audioRecordingInputBar else { return }
        if audioRecordingInputBar.superview == nil {
            return
        }
                
        messageInputBar.alpha = 0.0
        
        if audioRecordingInputBar.placeholderViewTopConstraint != nil {
            audioRecordingInputBar.placeholderViewTopConstraint.isActive = false
            audioRecordingInputBar.layoutIfNeeded()
        }
                
        UIView.animate(withDuration: 0.2, animations: {
            self.audioRecordingInputBar?.alpha = 0.0
            self.messageInputBar.alpha = 1.0
            self.audioRecordingInputBar?.viewHeightConstraint.constant = self.storedMessageInputBarHeight
            self.audioRecordingInputBar?.layoutIfNeeded()
        }, completion: { _ in
            self.audioRecordingInputBar?.cancelRecordingIfNeeded()
            self.audioRecordingInputBar?.removeFromSuperview()
            self.audioRecordingInputBar = nil
            
            if let handler = completionBlock {
                handler()
            }
        })
    }
    
    private func textInputToVoiceInputBarSwitch() {
        
        storedMessageInputBarHeight = messageInputBar.bounds.height
        
        let audioRecordingInputBar = AudioRecordingInputBar.instanceFromNib
        audioRecordingInputBar.delegate = self
        
        audioRecordingInputBar.alpha = 0.0
        self.wrap(audioRecordingInputBar)
        
        audioRecordingInputBar.startRecording()
        
        messageInputBar.alpha = 0.5
        
        self.audioRecordingInputBar = audioRecordingInputBar
        
        UIView.animate(withDuration: 0.2, animations: {
            self.audioRecordingInputBar?.alpha = 1.0
            self.messageInputBar.alpha = 0.0
        })
    }
    
    func cancelRecordingIfNeeded() {
        if audioRecordingInputBar != nil {
            cancelRecordingAndSwitchToTextInput()
        }
    }
        
    private func stopRecordingAndSwitchToTextInput() {
        delegate?.voiceRecordingEnded()
        do {
            if let clipPath = try audioRecordingInputBar?.stopRecording() {
                self.delegate?.tappedSendAudio(atPath: clipPath)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            voiceInputBarToTextInputSwitch()
        } catch AudioRecordingInputBar.RecordError.durationShorterThanASecond {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            voiceInputBarToTextInputSwitch {
                self.delegate?.showTapAndHoldMessage()
            }
        } catch {
            MEGALogDebug("Recording error \(error.localizedDescription)")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            voiceInputBarToTextInputSwitch()
        }
    }
    
    private func cancelRecordingAndSwitchToTextInput() {
        audioRecordingInputBar?.cancelRecording()
        delegate?.voiceRecordingEnded()
        voiceInputBarToTextInputSwitch()
    }
    
    private func keyboardFrameChangedNotification() -> any NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let `self` = self,
                self.voiceRecordingViewEnabled,
                self.messageInputBar.isTextViewTheFirstResponder(),
                let userInfo = notification.userInfo,
                let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
                let animationDuration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
                else {
                return
            }
            
            if keyboardHeight - self.frame.height > 0.0 {
                let defaultAnimationDuration = self.animationDuration
                self.animationDuration = animationDuration
                self.voiceRecordingViewEnabled = false
                self.animationDuration = defaultAnimationDuration
            }
        }
    }
    
    // MARK: - Gesture callback methods.
    
    @objc func fingerLiftUpDetected(_ gesture: FingerLiftupGestureRecognizer) {
        guard gesture.state == .ended,
            let audioRecordingInputBar,
            audioRecordingInputBar.superview != nil,
            audioRecordingInputBar.locked == false else {
                return
        }
        
        stopRecordingAndSwitchToTextInput()
    }
    
    @objc func longPress(_ longPressGesture: UILongPressGestureRecognizer) {
        guard longPressGesture.state == .began else {
            return
        }

        let loc = longPressGesture.location(in: longPressGesture.view)
        
        guard
            messageInputBar.superview != nil,
            messageInputBar.isMicButtonPresent(atLocation: loc),
            let delegate = delegate else {
            return
        }
            
        guard delegate.canRecordAudio else {
            delegate.requestOrInformAudioPermissions()
            return
        }
        
        guard !delegate.existsActiveCall else {
            delegate.presentActiveCall()
            return
        }
        
        textInputToVoiceInputBarSwitch()
    }
    
    @objc func pan(_ panGesture: UIPanGestureRecognizer) {
        guard let gestureView = panGesture.view,
            let audioRecordingInputBar,
            audioRecordingInputBar.superview != nil,
            audioRecordingInputBar.locked == false else {
            return
        }
        
        fingerLiftupGesture.failGestureIfRecognized()

        let translation = panGesture.translation(in: gestureView).simD2
        let trashTranslationRequiredInTotal =  0.6 * bounds.height
        let lockTranslationRequiredInTotal = 0.4 * bounds.height

        switch panGesture.state {
        case .began:
            initialTranslation = translation
        case .changed:
            if let initialValue = initialTranslation {
                let difference = translation - initialValue

                if difference.point.x < difference.point.y {
                    let progress = abs(difference.point.x)
                    let test = min(1.0, progress / trashTranslationRequiredInTotal)
                    audioRecordingInputBar.moveToTrash(test)
                } else {
                    let progress = abs(difference.point.y)
                    let test = min(1.0, progress / lockTranslationRequiredInTotal)
                    audioRecordingInputBar.lock(test)
                }
            }
        case .ended, .cancelled:
            if let initialValue = initialTranslation {
                let difference = translation - initialValue

                if difference.point.x < difference.point.y
                    && abs(difference.point.x) >= (trashTranslationRequiredInTotal * 0.75) {
                    self.cancelRecordingAndSwitchToTextInput()
                } else if difference.point.y < difference.point.x
                    && abs(difference.point.y) >= (lockTranslationRequiredInTotal * 0.75) {
                    audioRecordingInputBar.lock { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        self.stopRecordingAndSwitchToTextInput()
                    }
                } else {
                    self.stopRecordingAndSwitchToTextInput()
                }
            }
        default:
            break
        }
    }
}

extension ChatInputBar: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gesture: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGesture: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension ChatInputBar: MessageInputBarDelegate {
    func messageInputBarDidExpand(_ messageInputBar: MessageInputBar) {
        delegate?.messageInputBarDidExpand(messageInputBar)
    }
    
    func messageInputBarDidCollapse(_ messageInputBar: MessageInputBar) {
        delegate?.messageInputBarDidCollapse(messageInputBar)
    }
    
    func didPasteImage(_ image: UIImage) {
        delegate?.didPasteImage(image)
    }
    
    func clearEditMessage() {
        delegate?.clearEditMessage()
    }
    
    func tappedAddButton(_ button: UIButton) {
        if voiceRecordingViewEnabled {
            voiceRecordingViewEnabled = false
            let time = DispatchTime.now() + Double(animationDuration/2.0)
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.delegate?.tappedAddButton(button)
            }
        } else {
            delegate?.tappedAddButton(button)
        }
    }

    func tappedSendButton(withText text: String) {
        delegate?.tappedSendButton(withText: text)
    }

    func tappedVoiceButton() {
        delegate?.tappedVoiceButton()
    }

    func typing(withText text: String) {
        delegate?.typing(withText: text)
    }
    
    func textDidEndEditing() {
        delegate?.textDidEndEditing()
    }
}

extension ChatInputBar: VoiceClipInputBarDelegate {
    func removeVoiceClipView(withClipPath path: String?) {
        if let clipPath = path {
            self.delegate?.tappedSendAudio(atPath: clipPath)
        }        
    }
    
    func voiceRecordingStarted() {
        delegate?.voiceRecordingStarted()
    }
    
    func voiceRecordingEnded() {
        delegate?.voiceRecordingEnded()
    }
}

extension ChatInputBar: AudioRecordingInputBarDelegate {
    func trashButtonTapped() {
        delegate?.voiceRecordingEnded()
        cancelRecordingAndSwitchToTextInput()
    }
    
    func audioRecordingStarted() {
        delegate?.voiceRecordingStarted()
    }
    
    func audioRecordingEnded() {
        delegate?.voiceRecordingEnded()
    }
}
