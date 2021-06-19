final class CreateTextFileAlertViewController: UIAlertController {
    var viewModel: CreateTextFileAlertViewModel!
    
    func configView() {
        title = TextEditorL10n.textFile
        addTextField { (textField) in
            textField.text = ".txt"
            textField.placeholder = TextEditorL10n.fileName
            textField.addTarget(self, action: #selector(self.createTextFileAlertTextFieldBeginEdit), for: .editingDidBegin)
            textField.addTarget(self, action: #selector(self.createTextFileAlertTextFieldDidChange), for: .editingChanged)
            textField.shouldReturnCompletion = {(textField) -> Bool in
                return (!(textField?.text?.mnz_isEmpty() ?? true) && !(textField?.text?.mnz_containsInvalidChars() ?? false));
            }
        }
        addAction(UIAlertAction(title: TextEditorL10n.cancel, style: .cancel, handler: nil))
        let createFileAlertAction = UIAlertAction(title: TextEditorL10n.create, style: .default) {_ in
            if MEGAReachabilityManager.isReachableHUDIfNot() {
                let textField = self.textFields?.first
                if let inputFileName = textField?.text {
                    let fileName = inputFileName
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
            let empty = textField.text?.mnz_isEmpty() ?? true
            rightButtonAction?.isEnabled = (!empty && !containsInvalidChars)
        }
    }
    
    @objc private func createTextFileAlertTextFieldBeginEdit(textField: UITextField) {
        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.beginningOfDocument)
    }
}
