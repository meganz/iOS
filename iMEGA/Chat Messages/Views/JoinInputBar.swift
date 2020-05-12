
import UIKit

class JoinInputBar: UIView {
    
    @IBOutlet weak var joinButton: UIButton!
    var buttonTappedHandler: ((UIButton) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let title = AMLocalizedString("Join", "Button text in public chat previews that allows the user to join the chat")
        joinButton.setTitle(title, for: .normal)        
    }
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        buttonTappedHandler?(sender)
    }
    
}
