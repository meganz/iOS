import Foundation
import MEGAL10n
import MEGASwift

class TapAndHoldMessageView: UIView {
    
    // MARK: - Properties
    
    @IBOutlet weak var label: UILabel!
    private var timer: Timer!
    
    // MARK: - Overriden method
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setLabelText()
    }
    
    // MARK: - Actions
    
    @IBAction func didTapClose(_ button: UIButton) {
        timer.invalidate()
        close()
    }
    
    @IBAction func didTap(tapGesture: UITapGestureRecognizer) {
        timer.invalidate()
        close()
    }
    
    // MARK: - Interface methods
    
    func add(toView view: UIView, bottom: CGFloat) {
        alpha = 0.0
        view.wrap(self, edgeInsets: .init(top: 0, left: 0, bottom: bottom, right: 0))
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        
        UIView.animate(withDuration: 0.4, animations: {
            self.alpha = 1.0
        }, completion: { _ in
            self.startTimer()
        })
    }
    
    // MARK: - Private methods
    
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
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
    
    private func setLabelText() {
        let voiceImageAttributedString = NSAttributedString.attributedString(fromImage: UIImage(resource: .voiceTip),
                                                                             fontCapHeight: label.font.capHeight)
        let separatorText = "%@"
        let tapAndHoldText = Strings.Localizable.tapAndHoldToRecordReleaseToSend(separatorText)
        let tapAndHoldTextComponents = tapAndHoldText.components(separatedBy: separatorText)
        
        guard let tapAndHoldFirstPartString = tapAndHoldTextComponents.first,
              let tapAndHoldLastPartString = tapAndHoldTextComponents.last else {
            MEGALogDebug("could not extract first and last part of tap and hold string")
            return
        }
        
        let attributedString = NSMutableAttributedString(attributedString: NSAttributedString(string: tapAndHoldFirstPartString))
        attributedString.append(voiceImageAttributedString)
        attributedString.append(NSAttributedString(string: tapAndHoldLastPartString))
        
        label.attributedText = attributedString
    }
    
}
