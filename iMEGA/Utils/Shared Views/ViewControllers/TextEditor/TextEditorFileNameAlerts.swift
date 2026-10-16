import MEGAL10n
import UIKit

/// The alerts that ask what to do with a file name. The text editor and the Markdown screen share them.
@MainActor
enum TextEditorFileNameAlerts {
    /// Asks what to do when the folder already has a file with the same name.
    static func makeDuplicateNameAlert(
        _ model: TextEditorDuplicateNameAlertModel,
        onRename: @escaping () -> Void,
        onReplace: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(title: model.alertTitle, message: model.alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: model.renameButtonTitle, style: .default) { _ in onRename() })
        alert.addAction(UIAlertAction(title: model.replaceButtonTitle, style: .default) { _ in onReplace() })
        alert.addAction(UIAlertAction(title: model.cancelButtonTitle, style: .cancel))
        return alert
    }

    /// Asks for a new file name. Rename stays off until the name is new and valid.
    static func makeRenameAlert(
        _ model: TextEditorRenameAlertModel,
        onRename: @escaping (String) -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(title: model.alertTitle, message: model.alertMessage, preferredStyle: .alert)
        let renameAction = UIAlertAction(title: Strings.Localizable.rename, style: .default) { [weak alert] _ in
            guard let newName = alert?.textFields?.first?.text else { return }
            onRename(newName)
        }
        renameAction.isEnabled = false

        alert.addTextField { textField in
            textField.text = model.textFileName
            textField.placeholder = model.textFileName
            textField.addAction(UIAction { action in
                guard let textField = action.sender as? UITextField else { return }
                selectNameWithoutExtension(in: textField)
            }, for: .editingDidBegin)
            textField.addAction(UIAction { [weak renameAction = renameAction] action in
                guard let textField = action.sender as? UITextField else { return }
                renameAction?.isEnabled = isNewValidName(textField)
                textField.textColor = textField.text?.mnz_containsInvalidChars() ?? false ? .systemRed : .label
            }, for: .editingChanged)
        }
        alert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alert.addAction(renameAction)
        return alert
    }

    private static func selectNameWithoutExtension(in textField: UITextField) {
        guard let name = textField.text else { return }
        let nsName = name as NSString
        let beginning = textField.beginningOfDocument
        let end: UITextPosition
        if nsName.pathExtension.isEmpty && name == nsName.deletingPathExtension {
            end = textField.endOfDocument
        } else {
            let dotRange = nsName.range(of: ".", options: .backwards)
            end = textField.position(from: beginning, offset: dotRange.location) ?? textField.endOfDocument
        }
        textField.selectedTextRange = textField.textRange(from: beginning, to: end)
    }

    private static func isNewValidName(_ textField: UITextField) -> Bool {
        let isEmpty = textField.text?.mnz_isEmpty() ?? true
        let hasInvalidCharacters = textField.text?.mnz_containsInvalidChars() ?? false
        let isUnchanged = textField.text == textField.placeholder
        return !isEmpty && !hasInvalidCharacters && !isUnchanged
    }
}
