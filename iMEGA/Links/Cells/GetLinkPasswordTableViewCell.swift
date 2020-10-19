import UIKit

class GetLinkPasswordTableViewCell: UITableViewCell {

    @IBOutlet weak var passwordView: PasswordView!

    func configurePasswordCell(password: String) {
        passwordView.topLabel.text = ""
        passwordView.toggleSecureButton.isHidden = false
        passwordView.passwordTextField.text = password
        passwordView.passwordTextField.isEnabled = false
        passwordView.gestureRecognizers?.forEach(passwordView.removeGestureRecognizer)
    }
}
