import Foundation

extension ChangePasswordViewController {
    @objc func passwordTextFieldDidChange(_ textField: UITextField) {
        let text = textField.text ?? ""
        
        if text.isEmpty {
            passwordStrengthContainer.isHidden = true
        } else {
            passwordStrengthContainer.isHidden = false
            passwordStrengthIndicatorView.update(
                with: MEGASdk.shared.passwordStrength(text),
                updateDescription: true
            )
        }
    }
    
    @objc func setupPasswordTextFieldTarget() {
        theNewPasswordView.passwordTextField.addTarget(
            self,
            action: #selector(passwordTextFieldDidChange(_:)),
            for: .editingChanged
        )
    }
}
