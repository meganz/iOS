import MEGADesignToken
import MEGAL10n
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

    private var delegate: (any SetLinkPasswordViewControllerDelegate)?
    
    class func instantiate(withDelegate delegate: (any SetLinkPasswordViewControllerDelegate)?) -> MEGANavigationController {
        guard let setLinkPasswordVC = UIStoryboard(name: "GetLink", bundle: nil).instantiateViewController(withIdentifier: "SetLinkPasswordViewControllerID") as? SetLinkPasswordViewController else {
            fatalError("Could not instantiate SetLinkPasswordViewController")
        }

        setLinkPasswordVC.delegate = delegate
        
        return MEGANavigationController.init(rootViewController: setLinkPasswordVC)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.Localizable.setPassword

        let cancelBarButtonItem = UIBarButtonItem(title: Strings.Localizable.cancel, style: .done, target: self, action: #selector(cancelBarButtonTapped))
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        passwordView.passwordTextField.returnKeyType = .next
        passwordView.passwordTextField.delegate = self
        confirmPasswordView.passwordTextField.delegate = self

        passwordView.passwordTextField.textContentType = .password
        confirmPasswordView.passwordTextField.textContentType = .newPassword
        
        passwordView.passwordTextField.becomeFirstResponder()
        
        encryptButton.setTitle(Strings.Localizable.encrypt, for: .normal)

        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        view.backgroundColor = TokenColors.Background.page
        encryptButton.setTitleColor(TokenColors.Text.primary, for: .normal)
        separators.forEach { $0.backgroundColor = UIColor.mnz_separator() }
        backgrounds.forEach {
            $0.backgroundColor = TokenColors.Background.page
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
            passwordView.setErrorState(true, withText: Strings.Localizable.passwordInvalidFormat)
            return false
        }
        if password.mnz_isEmpty() {
            passwordView.setErrorState(true, withText: Strings.Localizable.passwordInvalidFormat)
            return false
        } else if MEGASdk.shared.passwordStrength(password as String) == .veryWeak {
            passwordView.setErrorState(true, withText: Strings.Localizable.pleaseStrengthenYourPassword)
            return false
        } else {
            passwordView.setErrorState(true, withText: Strings.Localizable.passwordPlaceholder)
            return true
        }
    }
    
    private func validateConfirmPassword() -> Bool {
        if passwordView.passwordTextField.text == confirmPasswordView.passwordTextField.text {
            passwordView.setErrorState(false, withText: Strings.Localizable.confirmPassword)
            return true
        } else {
            passwordView.setErrorState(true, withText: Strings.Localizable.passwordsDoNotMatch)
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
                passwordView.setErrorState(false, withText: Strings.Localizable.passwordPlaceholder)
                passwordStrenghtIndicatorView.update(with: MEGASdk.shared.passwordStrength(text), updateDescription: false)
            }
        } else if textField == confirmPasswordView.passwordTextField {
            confirmPasswordView.setErrorState(false, withText: Strings.Localizable.confirmPassword)
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
