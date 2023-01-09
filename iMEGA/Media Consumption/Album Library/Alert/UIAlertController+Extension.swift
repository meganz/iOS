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
            alert.action?(nil)
        })
        let textField = self.textFields?.first
        let affirmativeAction = UIAlertAction(title: alert.affirmativeButtonTitle, style: .default) { _ in
            alert.action?(textField?.text)
        }
        addAction(affirmativeAction)
        
        func actionFor(textField: UITextField, within alert: UIAlertController, viewModel: TextFieldAlertViewModel) -> UIAction {
            UIAction(handler: { _ in
                guard let updatedText = textField.text else { return }
                var isEnabled = true
                if let errorText = viewModel.validator?(updatedText) {
                    alert.title = errorText
                    textField.textColor = UIColor.mnz_redError()
                    isEnabled = false
                } else {
                    alert.title = viewModel.title
                    textField.textColor = UIColor.mnz_label()
                    isEnabled = true
                }
                alert.actions.last?.isEnabled = isEnabled
            })
        }
    }
}
