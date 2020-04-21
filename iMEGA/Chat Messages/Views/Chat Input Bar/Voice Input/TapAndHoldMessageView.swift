
import Foundation

class TapAndHoldMessageView: UIView {
    
    //MARK: - Properties

    @IBOutlet weak var label: UILabel!
    private var timer: Timer!
    
    //MARK: - Overriden method
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setLabelText()
    }
    
    //MARK: - Actions

    @IBAction func didTapClose(_ button: UIButton) {
        timer.invalidate()
        close()
    }
    
    @IBAction func didTap(tapGesture: UITapGestureRecognizer) {
        timer.invalidate()
        close()
    }
    
    //MARK: - Interface methods

    func add(toView view: UIView, bottom: CGFloat) {
        alpha = 0.0
        view.addSubview(self)
        autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0.0, left: 0.0, bottom: bottom, right: 0.0))
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        
        UIView.animate(withDuration: 0.4, animations: {
            self.alpha = 1.0
        }) { _ in
            self.startTimer()
        }
    }
    
    //MARK: - Private methods
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.close()
        }
    }
    
    private func close() {
        guard superview != nil else {
            return
        }
        
        UIView.animate(withDuration: 0.4, animations: {
            self.alpha = 0.0
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    private func setLabelText() {
        let voiceImageAttributedString = NSAttributedString.mnz_attributedString(fromImageNamed: "voiceTip",
                                                                                 fontCapHeight: label.font.capHeight)
        
        let tapAndHoldText = AMLocalizedString("Tap and hold %@ to record, release to send",
                                               "Tooltip shown when the user presses but does not hold the microphone icon to send a voice clip")
        let tapAndHoldTextComponents = tapAndHoldText.components(separatedBy: "%@")
        
        let attributedString = NSMutableAttributedString(attributedString: NSAttributedString(string: tapAndHoldTextComponents.first!))
        attributedString.append(voiceImageAttributedString!)
        attributedString.append(NSAttributedString(string: tapAndHoldTextComponents.last!))
        
        label.attributedText = attributedString
    }
    
}
