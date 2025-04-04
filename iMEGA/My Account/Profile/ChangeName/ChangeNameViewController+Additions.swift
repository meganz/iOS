import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwift

extension ChangeNameViewController: UITextFieldDelegate {
    private enum Constants {
        static let maxNumOfCharacters: Int = 40
    }
    
    private enum TextFieldType: Int {
        case firstName = 0
        case lastName = 1
    }
    
    private func hasValidNameFormat() -> Bool {
        firstNameTextField.text = firstNameTextField.text?.trim
        lastNameTextField.text = lastNameTextField.text?.trim
        
        if firstNameTextField.text?.isEmpty ?? true {
            SVProgressHUD.showError(withStatus: Strings.Localizable.nameInvalidFormat)
            firstNameTextField.becomeFirstResponder()
            return false
        }
        
        return true
    }
    
    private func update(attribute: UserAttributeEntity, value: String) {
        Task { @MainActor in
            let userAttributeUC = UserAttributeUseCase(repo: UserAttributeRepository.newRepo)
            SVProgressHUD.show()
            do {
                try await userAttributeUC.updateUserAttribute(attribute, value: value)
                SVProgressHUD.showSuccess(withStatus: Strings.Localizable.youHaveSuccessfullyChangedYourProfile)
                dismiss(animated: true)
            } catch let megaError as MEGAError {
                SVProgressHUD.showError(withStatus: Strings.localized(megaError.name, comment: ""))
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case TextFieldType.firstName.rawValue:
            lastNameTextField.becomeFirstResponder()
        case TextFieldType.lastName.rawValue:
            validateAndSaveUpdatedName()
        default: break
        }
        
        return true
    }
    
    @objc func validateAndSaveUpdatedName() {
        firstNameTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            if hasValidNameFormat() {
                saveButton.isEnabled = false
                
                if hasTextfieldBeenEdited(firstNameTextField.text ?? "", tag: firstNameTextField.tag) {
                    update(attribute: .firstName, value: firstNameTextField.text ?? "")
                }
                
                if hasTextfieldBeenEdited(lastNameTextField.text ?? "", tag: lastNameTextField.tag) {
                    update(attribute: .lastName, value: lastNameTextField.text ?? "")
                }
            }
        } else {
            saveButton.isEnabled = true
        }
    }
    
    @objc func hasTextfieldBeenEdited(_ currentText: String, tag: Int) -> Bool {
        let trimmedText = currentText.trim
        switch tag {
        case TextFieldType.firstName.rawValue:
            return firstName != trimmedText
        case TextFieldType.lastName.rawValue:
            return lastName != trimmedText
        default: break
        }
        
        return false
    }
    
    // MARK: - UITextFieldDelegate
    public func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField.tag {
        case TextFieldType.firstName.rawValue, TextFieldType.lastName.rawValue:
            textField.text = textField.text?.trim
        default: break
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        
        var shouldSaveButtonBeEnabled = true
        
        let hasCurrentTextfieldBeenEdited = hasTextfieldBeenEdited(text ?? "", tag: textField.tag)
        let areAnyTextfieldsEmpty = (text?.isEmpty ?? true) || (textField.tag == TextFieldType.lastName.rawValue ? (firstNameTextField.text?.isEmpty ?? true) : (lastNameTextField.text?.isEmpty ?? true))
        
        if areAnyTextfieldsEmpty {
            shouldSaveButtonBeEnabled = false
        } else if hasCurrentTextfieldBeenEdited {
            shouldSaveButtonBeEnabled = true
        } else {
            let secondaryTextField = textField.tag == TextFieldType.firstName.rawValue ? lastNameTextField : firstNameTextField
            shouldSaveButtonBeEnabled = hasTextfieldBeenEdited(secondaryTextField?.text ?? "", tag: secondaryTextField?.tag ?? 0)
        }
        
        saveButton.isEnabled = shouldSaveButtonBeEnabled
        
        return text?.count ?? 0 <= Constants.maxNumOfCharacters
    }
    
    // MARK: Appearance
    
    @objc func defaultBackgroundColor() -> UIColor {
        TokenColors.Background.page
    }
    
    @objc func primaryTextcolor() -> UIColor {
        TokenColors.Text.primary
    }
}
