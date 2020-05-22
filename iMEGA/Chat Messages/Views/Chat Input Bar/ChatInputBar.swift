

import UIKit
import simd

protocol ChatInputBarDelegate: MessageInputBarDelegate {
    func tappedSendAudio(atPath path: String)
    func recordingViewShown(withAdditionalHeight height: CGFloat)
    func recordingViewHidden()
    func canRecordAudio() -> Bool
}

class ChatInputBar: UIView {

    // MARK:- Gestures properties

    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action:#selector(longPress))
        recognizer.minimumPressDuration = 0.1
        recognizer.delegate = self
        return recognizer
    }()
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action:#selector(pan))
        recognizer.delegate = self
        return recognizer
    }()
    
    private lazy var fingerLiftupGesture: FingerLiftupGestureRecognizer = {
        let recognizer = FingerLiftupGestureRecognizer(target: self, action: #selector(fingerLiftUpDetected))
        recognizer.cancelsTouchesInView = false;
        recognizer.delegate = self
        return recognizer
    }()
    
    // MARK:- Private properties

    private let messageInputBar = MessageInputBar.instanceFromNib
    private var audioRecordingInputBar: AudioRecordingInputBar!
    private var voiceClipInputBar: VoiceClipInputBar!
    private var initialTranslation: SIMD2<Double>?
    private var storedMessageInputBarHeight: CGFloat = 0.0
    private var voiceToTextSwitching = false
    private var animationDuration: TimeInterval = 0.4
    
    // MARK:- Interface properties

    weak var delegate: ChatInputBarDelegate?
    
    var recordingViewEnabled: Bool = false {
        didSet {
            messageInputBar.hideRightButtonHolderView = recordingViewEnabled
            
            if recordingViewEnabled {
                if let messageInputBarBottomConstraint = constraints
                    .filter({ $0.firstAttribute == .bottom && $0.firstItem === self.messageInputBar })
                    .first,
                    let messageInputBarTopConstraint = constraints
                    .filter({ $0.firstAttribute == .top && $0.firstItem === self.messageInputBar })
                    .first {
                    messageInputBarBottomConstraint.isActive = false
                    messageInputBarTopConstraint.isActive = false
                }
                
                voiceClipInputBar = VoiceClipInputBar.instanceFromNib
                voiceClipInputBar.delegate = self
                addSubview(voiceClipInputBar)
                voiceClipInputBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
                let voiceClipInputBarHeight = self.voiceClipInputBar.bounds.height
                let voiceClipInputBarHeightConstraint = voiceClipInputBar.heightAnchor.constraint(equalToConstant: 0)
                voiceClipInputBarHeightConstraint.isActive = true
                voiceClipInputBar.autoPinEdge(.top, to: .bottom, of: messageInputBar)
                self.layoutIfNeeded()
                
                UIView.animate(withDuration: animationDuration, animations: {
                    voiceClipInputBarHeightConstraint.constant = voiceClipInputBarHeight
                    self.layoutIfNeeded()
                }) { _ in
                    self.messageInputBar.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
                    self.layoutIfNeeded()
                    self.invalidateIntrinsicContentSize()
                    self.delegate?.recordingViewShown(withAdditionalHeight: self.voiceClipInputBar.frame.height)
                }
            } else {
                guard let messageInputBarTopConstraint = constraints
                    .filter({ $0.firstAttribute == .top && $0.firstItem === self.messageInputBar })
                    .first,
                    let voiceClipInputBarHeightConstraint = voiceClipInputBar.constraints
                        .filter({ $0.firstAttribute == .height })
                        .first else {
                        return
                }
                
                messageInputBarTopConstraint.isActive = false
                layoutIfNeeded()

                UIView.animate(withDuration: animationDuration, animations: {
                    voiceClipInputBarHeightConstraint.constant = 0.0
                    self.layoutIfNeeded()
                }) { _ in
                    self.messageInputBar.autoPinEdge(toSuperviewEdge: .bottom)
                    self.messageInputBar.autoPinEdge(toSuperviewEdge: .top)

                    self.voiceClipInputBar.removeFromSuperview()
                    self.voiceClipInputBar = nil
                    
                    self.layoutIfNeeded()
                    self.invalidateIntrinsicContentSize()
                    
                    self.delegate?.recordingViewHidden()
                }
            }
            
        }
    }

    // MARK:- overriden properties and methods

    override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addGestureRecognizer(longPressGesture)
        addGestureRecognizer(panGesture)
        addGestureRecognizer(fingerLiftupGesture)
        
        addMessageInputBar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dismissKeyboard() {
        messageInputBar.dismissKeyboard()
    }
    
    //MARK: - Interface methods.
    
    func set(text: String) {
        guard messageInputBar.superview != nil else {
            fatalError("message input bar was not the shown to the user")
        }
        
        messageInputBar.set(text: text)
    }
    
    // MARK: - Private methods.
    
    private func addMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.keyboardShown = { [weak self] in
            guard let `self` = self,
                self.recordingViewEnabled else {
                return
            }

            self.recordingViewEnabled = false
        }
        addSubview(messageInputBar)
        messageInputBar.autoPinEdgesToSuperviewEdges()
    }
    
    private func voiceInputBarToTextInputSwitch() {
        voiceToTextSwitching = true
        
        messageInputBar.alpha = 0.0
        addMessageInputBar()
        
        audioRecordingInputBar.placeholderViewTopConstraint.isActive = false
        audioRecordingInputBar.layoutIfNeeded()
                
        UIView.animate(withDuration: 0.2, animations: {
            self.audioRecordingInputBar.alpha = 0.0
            self.messageInputBar.alpha = 1.0
            self.audioRecordingInputBar.viewHeightConstraint.constant = self.storedMessageInputBarHeight
            self.audioRecordingInputBar.layoutIfNeeded()
        }) { _ in
            self.audioRecordingInputBar.removeFromSuperview()
            self.audioRecordingInputBar = nil
            self.voiceToTextSwitching = false
        }
    }
    
    private func textInputToVoiceInputBarSwitch() {
        storedMessageInputBarHeight = messageInputBar.bounds.height
        
        audioRecordingInputBar = AudioRecordingInputBar.instanceFromNib
        audioRecordingInputBar.trashButtonTapHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.cancelRecordingAndSwitchToTextInput()
        }
        
        audioRecordingInputBar.alpha = 0.0
        addSubview(audioRecordingInputBar)
        audioRecordingInputBar.autoPinEdgesToSuperviewEdges()
        
        messageInputBar.alpha = 0.5
        
        UIView.animate(withDuration: 0.2, animations: {
            self.audioRecordingInputBar.alpha = 1.0
            self.messageInputBar.alpha = 0.0
        }) { _ in
            if !self.voiceToTextSwitching {
                self.messageInputBar.removeFromSuperview()
                self.messageInputBar.alpha = 1.0
            }
        }
    }
    
    private func stopRecordingAndSwitchToTextInput() {
        if let clipPath = audioRecordingInputBar.stopRecording() {
            self.delegate?.tappedSendAudio(atPath: clipPath)
        }
        
        voiceInputBarToTextInputSwitch()
    }
    
    private func cancelRecordingAndSwitchToTextInput() {
        audioRecordingInputBar.cancelRecording()
        voiceInputBarToTextInputSwitch()
    }
    
    // MARK:- Gesture callback methods.
    
    @objc func fingerLiftUpDetected(_ gesture: FingerLiftupGestureRecognizer) {
        guard gesture.state == .ended,
            audioRecordingInputBar != nil,
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
        if messageInputBar.superview != nil,
            messageInputBar.isMicButtonPresent(atLocation: loc),
            let delegate = delegate,
            delegate.canRecordAudio() {
            textInputToVoiceInputBarSwitch()
        }
    }
    
    @objc func pan(_ panGesture: UIPanGestureRecognizer) {
        guard let gestureView = panGesture.view,
            audioRecordingInputBar != nil,
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
    func tappedAddButton(_ button: UIButton) {
        if recordingViewEnabled {
            recordingViewEnabled = false
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
}

extension ChatInputBar: VoiceClipInputBarDelegate {
    func removeVoiceClipView(withClipPath path: String?) {
        if let clipPath = path {
            self.delegate?.tappedSendAudio(atPath: clipPath)
        }
        
        recordingViewEnabled = false
    }
}
