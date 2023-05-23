
import Foundation

class EmptyMeetingMessageView: UIView {
    @IBOutlet weak var messageLabel: UILabel!
    
    private let minWidth: CGFloat = 160.0
    private var maxWidth: CGFloat {
        UIScreen.main.bounds.size.width - defaultMargin
    }
    private let minHeight: CGFloat = 44
    private let defaultMargin: CGFloat = 32
    
    override var intrinsicContentSize: CGSize {
        let labelWidth = messageLabel.intrinsicContentSize.width
        if labelWidth + defaultMargin < minWidth {
            return CGSize(width: minWidth, height: minHeight)
        } else if labelWidth + defaultMargin > maxWidth {
            return CGSize(width: maxWidth, height: minHeight * 2)
        } else {
            return CGSize(width: labelWidth + defaultMargin, height: minHeight)
        }
    }
}
