final class CreateTextFileAlertViewController: UIAlertController {
    var viewModel: CreateTextFileAlertViewModel!
    
    func configView() {
        title = Strings.Localizable.newTextFile
        addTextField { (textField) in
            textField.text = ".txt"
            textField.placeholder = Strings.Localizable.fileName
            textField.addTarget(self, action: #selector(self.createTextFileAlertTextFieldBeginEdit), for: .editingDidBegin)
            textField.addTarget(self, action: #selector(self.createTextFileAlertTextFieldDidChange), for: .editingChanged)
            textField.shouldReturnCompletion = {(textField) -> Bool in
                return (!(textField?.text?.mnz_isEmpty() ?? true) && !(textField?.text?.mnz_containsInvalidChars() ?? false));
            }
        }
        addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
        let createFileAlertAction = UIAlertAction(title: Strings.Localizable.createFolderButton, style: .default) {_ in
            if MEGAReachabilityManager.isReachableHUDIfNot() {
                let textField = self.textFields?.first
                if let inputFileName = textField?.text {
                    let fileName = inputFileName.trimmingCharacters(in: .whitespaces)
                    self.viewModel.dispatch(.createTextFile(fileName))
                }
            }
        }
        addAction(createFileAlertAction)
    }

    @objc private func createTextFileAlertTextFieldDidChange(textField: UITextField) {
        if let newFileAC = UIApplication.mnz_visibleViewController() as? UIAlertController {
            let rightButtonAction = newFileAC.actions.last
            let containsInvalidChars = textField.text?.mnz_containsInvalidChars() ?? false
            textField.textColor = containsInvalidChars ? UIColor.mnz_redError() : UIColor.mnz_label()
            newFileAC.title = newFileNameAlertTitle(invalidChars: containsInvalidChars)
            let empty = textField.text?.mnz_isEmpty() ?? true
            rightButtonAction?.isEnabled = (!empty && !containsInvalidChars)
        }
    }
    
    @objc private func createTextFileAlertTextFieldBeginEdit(textField: UITextField) {
        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.beginningOfDocument)
    }
    
    @objc private func newFileNameAlertTitle(invalidChars containsInvalidChars: Bool) -> String {
        guard containsInvalidChars else {
            return Strings.Localizable.newTextFile
        }
        return Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharacters)
    }
}
