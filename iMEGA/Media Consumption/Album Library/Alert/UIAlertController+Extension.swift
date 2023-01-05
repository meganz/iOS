import Foundation

extension UIAlertController {
    convenience init(alert: TextFieldAlertViewModel) {
        self.init(title: alert.title, message: nil, preferredStyle: .alert)
        self.addTextField { textField in
            textField.placeholder = alert.placeholderText
            textField.text = alert.textString
            let textFieldAction = actionFor(textField: textField, within: self, viewModel: alert)
            textField.addAction(textFieldAction, for: .editingChanged)
        }
        
        addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel) { _ in
            alert.action(nil)
        })
        let textField = self.textFields?.first
        let affirmativeAction = UIAlertAction(title: alert.affirmativeButtonTitle, style: .default) { _ in
            alert.action(textField?.text)
        }
        addAction(affirmativeAction)
        affirmativeAction.isEnabled = !alert.textString.mnz_isEmpty()
        
        func actionFor(textField: UITextField, within alert: UIAlertController, viewModel: TextFieldAlertViewModel) -> UIAction {
            UIAction(handler: { _ in
                guard let updatedText = textField.text else { return }
                let containsInvalidChars = updatedText.mnz_containsInvalidChars()
                alert.title = containsInvalidChars ? viewModel.invalidTextTitle : viewModel.title
                textField.textColor = containsInvalidChars ? UIColor.mnz_redError() : UIColor.mnz_label()
                let empty = updatedText.mnz_isEmpty()
                alert.actions.last?.isEnabled = (!empty && !containsInvalidChars)
            })
        }
    }
}
