

import UIKit
import simd

protocol ChatMessageAndAudioInputBarDelegate: MessageInputBarDelegate { }

class ChatMessageAndAudioInputBar: UIView {
    let messageInputBar = MessageInputBar.instanceFromNib
    lazy var audioRecordingInputBar = AudioRecordingInputBar.instanceFromNib
    
    lazy var longPressGesture: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action:#selector(longPress))
        recognizer.delegate = self
        return recognizer
    }()
    
    lazy var panGesture: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action:#selector(pan))
        recognizer.delegate = self
        return recognizer
    }()
    
    // MARK:- Interface properties

    weak var delegate: ChatMessageAndAudioInputBarDelegate?

    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addGestureRecognizer(longPressGesture)
        addGestureRecognizer(panGesture)
        
        addMessageInputBar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addMessageInputBar() {
        messageInputBar.delegate = self
        addSubview(messageInputBar)
        messageInputBar.autoPinEdgesToSuperviewEdges()
    }
    
    @objc func longPress(_ longPressGesture: UILongPressGestureRecognizer) {
        guard longPressGesture.state == .began else {
            return
        }

        let loc = longPressGesture.location(in: longPressGesture.view)
        if messageInputBar.superview != nil
            && messageInputBar.isMicButtonPresent(atLocation: loc) {
            
            audioRecordingInputBar.alpha = 0.0
            addSubview(audioRecordingInputBar)
            audioRecordingInputBar.autoPinEdgesToSuperviewEdges()
            
            messageInputBar.alpha = 0.5
            
            UIView.animate(withDuration: 0.4, animations: {
                self.audioRecordingInputBar.alpha = 1.0
                self.messageInputBar.alpha = 0.0
            }) { _ in
                self.messageInputBar.removeFromSuperview()
                self.messageInputBar.alpha = 1.0
            }

        }
    }
    
    var initialTranslation: SIMD2<Double>?
    
    @objc func pan(_ panGesture: UIPanGestureRecognizer) {
        guard let gestureView = panGesture.view,
            audioRecordingInputBar.superview != nil else {
            return
        }

        let translation = panGesture.translation(in: gestureView).simD2

        switch panGesture.state {
        case .began:
            initialTranslation = translation
        case .changed:
            if let initialValue = initialTranslation {
                let difference = translation - initialValue

                if difference.point.x < difference.point.y {
                    let progress = abs(difference.point.x)
                    let progressComplete = 0.6 * bounds.width
                    let test = min(1.0, progress / progressComplete)
                    audioRecordingInputBar.moveToTrash(test)
                } else {
                    let progress = abs(difference.point.y)
                    let progressComplete = 0.4 * bounds.height
                    let test = min(1.0, progress / progressComplete)
                    audioRecordingInputBar.lock(test)
                }
            }
        case .ended, .cancelled:
            if let initialValue = initialTranslation {
                let difference = translation - initialValue

                if difference.point.x < difference.point.y
                    && abs(difference.point.x) > (0.15 * bounds.width) {
                    print("move to trash")
                } else if difference.point.y < difference.point.x {
                    print("lock voice")
                } else {
                }
            }
        default:
            break
        }
        
    }
}
extension ChatMessageAndAudioInputBar: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }
}


extension ChatMessageAndAudioInputBar: MessageInputBarDelegate {

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

extension CGPoint {
    var simD2: SIMD2<Double> {
        return SIMD2(x: x.native, y: y.native)
    }
}


extension SIMD2 where Scalar == Double {
    var point: CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }
}
