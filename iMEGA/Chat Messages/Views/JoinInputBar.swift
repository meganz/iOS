
import UIKit

class JoinInputBar: UIView {
    
    @IBOutlet weak var joinButton: UIButton!
    var buttonTappedHandler: ((UIButton) -> Void)?

    @IBOutlet weak var joiningOrLeavingLabel: UILabel!
    @IBOutlet weak var joiningOrLeavingView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let title = Strings.Localizable.join
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
            joiningOrLeavingLabel.text = Strings.Localizable.joining

        case.leaving:
            joinButton.isHidden = true
            joiningOrLeavingView.isHidden = false
            indicator.startAnimating()
            joiningOrLeavingLabel.text = Strings.Localizable.leaving

        default:
            joinButton.isHidden = false
            joiningOrLeavingView.isHidden = true
            indicator.stopAnimating()
        }
    }
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        buttonTappedHandler?(sender)
    }
    
}
