
import UIKit

class JoinInputBar: UIView {
    
    @IBOutlet weak var joinButton: UIButton!
    var buttonTappedHandler: ((UIButton) -> Void)?

    @IBOutlet weak var joiningOrLeavingLabel: UILabel!
    @IBOutlet weak var joiningOrLeavingView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let title = AMLocalizedString("Join", "Button text in public chat previews that allows the user to join the chat")
        joinButton.setTitle(title, for: .normal)
        indicator.startAnimating()
        
    }
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        buttonTappedHandler?(sender)
    }
    
}
