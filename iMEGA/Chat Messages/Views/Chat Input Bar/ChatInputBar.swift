

import UIKit
import simd

protocol ChatMessageAndAudioInputBarDelegate: MessageInputBarDelegate {
    func tappedSendAudio(atPath path: String)
}

class ChatInputBar: UIView {

    // MARK:- Gestures properties

    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action:#selector(longPress))
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
    private var initialTranslation: SIMD2<Double>?
    private var storedMessageInputBarHeight: CGFloat = 0.0
    private var voiceToTextSwitching = false
    
    // MARK:- Interface properties

    weak var delegate: ChatMessageAndAudioInputBarDelegate?

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
    
    // MARK: - Private methods.
    
    private func addMessageInputBar() {
        messageInputBar.delegate = self
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
    
    // MARK:- Gesture callback methods.
    
    @objc func fingerLiftUpDetected(_ gesture: FingerLiftupGestureRecognizer) {
        guard gesture.state == .ended,
            audioRecordingInputBar != nil,
            audioRecordingInputBar.superview != nil,
            audioRecordingInputBar.locked == false else {
                return
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        audioRecordingInputBar.cancelRecording()
        voiceInputBarToTextInputSwitch()
    }
    
    @objc func longPress(_ longPressGesture: UILongPressGestureRecognizer) {
        guard longPressGesture.state == .began else {
            return
        }

        let loc = longPressGesture.location(in: longPressGesture.view)
        if messageInputBar.superview != nil
            && messageInputBar.isMicButtonPresent(atLocation: loc) {
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
                    audioRecordingInputBar.cancelRecording()
                    voiceInputBarToTextInputSwitch()
                } else if difference.point.y < difference.point.x
                    && abs(difference.point.y) >= (lockTranslationRequiredInTotal * 0.75) {
                    audioRecordingInputBar.lock { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        if let clipPath = self.audioRecordingInputBar.stopRecording() {
                            self.delegate?.tappedSendAudio(atPath: clipPath)
                        }
                        
                        self.voiceInputBarToTextInputSwitch()
                    }
                } else {
                    audioRecordingInputBar.cancelRecording()
                    voiceInputBarToTextInputSwitch()
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

    func tappedAddButton() {
        delegate?.tappedAddButton()
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
