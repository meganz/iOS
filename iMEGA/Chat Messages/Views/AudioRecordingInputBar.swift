
import UIKit

class AudioRecordingInputBar: UIView {

    @IBOutlet weak var voiceViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var voiceViewBottomConstraint: NSLayoutConstraint!
    
    var voiceViewTrailingDefaultValue: CGFloat!
    var voiceViewBottomDefaultValue: CGFloat!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        voiceViewTrailingDefaultValue = voiceViewTrailingConstraint.constant
        voiceViewBottomDefaultValue = voiceViewBottomConstraint.constant
    }

    override var intrinsicContentSize: CGSize {
        return .zero
    }
}
