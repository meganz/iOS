import UIKit

protocol SetLinkPasswordViewControllerDelegate {
    func setLinkPassword(_ setLinkPassword: SetLinkPasswordViewController, password: String)
    func setLinkPasswordCanceled(_ setLinkPassword: SetLinkPasswordViewController)
}

class SetLinkPasswordViewController: UIViewController {

    @IBOutlet weak var passwordView: PasswordView!
    @IBOutlet weak var passwordStrenghtIndicatorView: PasswordStrengthIndicatorView!
    @IBOutlet weak var passwordStrenghtIndicatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var confirmPasswordView: PasswordView!
    @IBOutlet weak var encryptButton: UIButton!
    @IBOutlet var separators: [UIView]!
    @IBOutlet var backgrounds: [UIView]!

    private var delegate: SetLinkPasswordViewControllerDelegate?
    private var link = String()
    
    class func instantiate(withLink link: String, delegate: SetLinkPasswordViewControllerDelegate?) -> MEGANavigationController {
        guard let setLinkPasswordVC = UIStoryboard(name: "GetLink", bundle: nil).instantiateViewController(withIdentifier: "SetLinkPasswordViewControllerID") as? SetLinkPasswordViewController else {
            fatalError("Could not instantiate SetLinkPasswordViewController")
        }

        setLinkPasswordVC.link = link
        setLinkPasswordVC.delegate = delegate
        
        return MEGANavigationController.init(rootViewController: setLinkPasswordVC)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = AMLocalizedString("Set Password", "Text for options in Get Link View to set password protection")

        let cancelBarButtonItem = UIBarButtonItem(title: AMLocalizedString("cancel"), style: .done, target: self, action: #selector(cancelBarButtonTapped))
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        passwordView.passwordTextField.returnKeyType = .next
        passwordView.passwordTextField.delegate = self
        confirmPasswordView.passwordTextField.delegate = self

        if #available(iOS 12.0, *) {
            passwordView.passwordTextField.textContentType = .password
            confirmPasswordView.passwordTextField.textContentType = .newPassword
        }
        
        passwordView.passwordTextField.becomeFirstResponder()
        
        encryptButton.setTitle(AMLocalizedString("encrypt", "The text of a button. This button will encrypt a link with a password."), for: .normal)

        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
            }
        }
    }
    
    private func updateAppearance() {
        view.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        encryptButton.setTitleColor(UIColor.mnz_turquoise(for: traitCollection), for: .normal)
        separators.forEach { $0.backgroundColor = UIColor.mnz_separator(for: traitCollection) }
        backgrounds.forEach { $0.backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        }
    }
    
    @objc private func cancelBarButtonTapped() {
        delegate?.setLinkPasswordCanceled(self)
    }
    
    @IBAction func encyptButtonTapped(_ sender: UIButton) {
        if validatePassword() && validateConfirmPassword() {
            guard let password = passwordView.passwordTextField.text else { return }
            self.delegate?.setLinkPassword(self, password: password)
        }
    }
    
    private func validatePassword() -> Bool {
        guard let password = passwordView.passwordTextField.text as NSString? else {
            passwordView.setErrorState(true, withText: AMLocalizedString("passwordInvalidFormat", "Message shown when the user enters a wrong password"))
            return false
        }
        if password.mnz_isEmpty() {
            passwordView.setErrorState(true, withText: AMLocalizedString("passwordInvalidFormat", "Message shown when the user enters a wrong password"))
            return false
        } else if MEGASdkManager.sharedMEGASdk().passwordStrength(password as String) == .veryWeak {
           passwordView.setErrorState(true, withText: AMLocalizedString("pleaseStrengthenYourPassword"))
            return false
        } else {
            passwordView.setErrorState(true, withText: AMLocalizedString("passwordPlaceholder", "Hint text to suggest that the user has to write his password"))
            return true
        }
    }
    
    private func validateConfirmPassword() -> Bool {
        if passwordView.passwordTextField.text == confirmPasswordView.passwordTextField.text {
            passwordView.setErrorState(false, withText: AMLocalizedString("confirmPassword", "Hint text where the user have to re-write the new password to confirm it"))
            return true
        } else {
            passwordView.setErrorState(true, withText: AMLocalizedString("passwordsDoNotMatch", "Error text shown when you have not written the same password"))
            return false
        }
    }
}

extension SetLinkPasswordViewController: UITextFieldDelegate {
 
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == passwordView.passwordTextField {
            passwordView.toggleSecureButton.isHidden = false
        } else if textField == confirmPasswordView.passwordTextField {
            confirmPasswordView.toggleSecureButton.isHidden = false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == passwordView.passwordTextField {
            passwordView.configureSecureTextEntry()
        } else if textField == confirmPasswordView.passwordTextField {
            confirmPasswordView.configureSecureTextEntry()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == passwordView.passwordTextField {
            let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
            if text.isEmpty {
                passwordStrenghtIndicatorHeightConstraint.constant = 0
            } else {
                passwordStrenghtIndicatorHeightConstraint.constant = 44.5
                passwordView.setErrorState(false, withText: AMLocalizedString("passwordPlaceholder", "Hint text to suggest that the user has to write his password"))
                passwordStrenghtIndicatorView.update(with: MEGASdkManager.sharedMEGASdk().passwordStrength(text), updateDescription: false)
            }
        } else if textField == confirmPasswordView.passwordTextField {
            confirmPasswordView.setErrorState(false, withText: AMLocalizedString("confirmPassword", "Hint text where the user have to re-write the new password to confirm it"))
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passwordView.passwordTextField {
            confirmPasswordView.passwordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordView.passwordTextField {
            confirmPasswordView.passwordTextField.resignFirstResponder()
        }
        
        return true
    }
}
