
import UIKit

class ChatBottomInfoScreen: UIView {
    @IBOutlet weak var label: UILabel!

    enum ViewType {
        case jumpToLatest
        case newMessages
    }
    
    var viewType: ViewType = .jumpToLatest {
        didSet {
            label.text = (viewType == .jumpToLatest) ? AMLocalizedString("jumpToLatest", "Label in a button that allows to jump to the latest item") : AMLocalizedString("newMessages", "Label in a button that allows to jump to the latest message")
        }
    }
    
    var tapHandler: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        viewType = .jumpToLatest
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        tapHandler?()
    }
}
