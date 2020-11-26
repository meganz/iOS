
import UIKit

class JoinInputBar: UIView {
    
    @IBOutlet weak var joinButton: UIButton!
    var buttonTappedHandler: ((UIButton) -> Void)?

    @IBOutlet weak var joiningOrLeavingLabel: UILabel!
    @IBOutlet weak var joiningOrLeavingView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let title = NSLocalizedString("Join", comment: "Button text in public chat previews that allows the user to join the chat")
        joinButton.setTitle(title, for: .normal)
        joinButton.isHidden = false
        joiningOrLeavingView.isHidden = true
    }
    
    func setJoinViewState(newState: JoinViewState) {
        switch newState {
        case .joining:
            joinButton.isHidden = true
            joiningOrLeavingView.isHidden = false
            indicator.startAnimating()
            joiningOrLeavingLabel.text = NSLocalizedString("Joining...", comment: "Label shown while joining a public chat")

        case.leaving:
            joinButton.isHidden = true
            joiningOrLeavingView.isHidden = false
            indicator.startAnimating()
            joiningOrLeavingLabel.text = NSLocalizedString("Leaving...", comment: "Label shown while leaving a public chat")

        default:
            joinButton.isHidden = false
            joiningOrLeavingView.isHidden = true
            indicator.stopAnimating()
            break
        }
    }
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        buttonTappedHandler?(sender)
    }
    
}
