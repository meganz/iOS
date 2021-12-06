
extension CustomModalAlertViewController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if !detailErrorLabel.isHidden {
            detailErrorLabel.isHidden = true
            detailTextField.layer.borderColor = UIColor.mnz_separator(for: traitCollection).cgColor
            detailTextField.text = ""
        }
    }
    
    @objc func showConfirmationTextError() {
        detailErrorLabel.isHidden = false
        detailErrorLabel.text = NSLocalizedString("dialog.confirmation.error.message", comment: "")
        detailErrorLabel.textColor = UIColor.mnz_red(for: traitCollection)
        detailTextField.layer.borderColor = UIColor.mnz_red(for: traitCollection).cgColor
        detailTextField.layer.cornerRadius = 4.0
        detailTextField.layer.borderWidth = 0.5
        detailTextField.layer.borderColor = UIColor.mnz_redError().cgColor
    }
}
