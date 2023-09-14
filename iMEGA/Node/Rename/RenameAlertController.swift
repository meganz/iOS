import MEGAL10n

final class RenameAlertController: UIAlertController, UITextFieldDelegate {
     var viewModel: RenameViewModel!
    
    func configView() {
        title = Strings.Localizable.rename
        message = viewModel.alertMessage(text: viewModel.textfieldText())
        
        addTextField { textField in
            textField.placeholder = self.viewModel.textfieldPlaceHolder()
            textField.text = self.viewModel.textfieldText()
            textField.returnKeyType = .done
            textField.delegate = self
            textField.addTarget(self, action: #selector(self.textFieldChanged(_:)), for: .editingChanged)
        }
        
        addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
        
        let renameAlertAction = UIAlertAction(title: Strings.Localizable.rename, style: .default) { [weak self] _ in
            guard let self, let textfieldText = self.textFields?.first?.text else { return }
            Task {
                await self.viewModel.rename(textfieldText)
            }
        }
        
        renameAlertAction.isEnabled = false
        addAction(renameAlertAction)
    }
    
    @objc private func textFieldChanged(_ textField: UITextField) {
        guard let textFieldText = textField.text else { return }
        
        title = viewModel.alertTitle(text: textFieldText)
        message = viewModel.alertMessage(text: textFieldText)
        textField.textColor = viewModel.alertTextsColor(text: textFieldText)
        actions.last?.isEnabled = viewModel.isActionButtonEnabled(text: textFieldText)
    }
}
