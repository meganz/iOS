import Foundation
import MEGAL10n

extension MEGANode {
    
    @MainActor
    @objc func showRenameNodeConfirmationAlert(from vc: UIViewController, completion: @escaping () -> Void) {
        let alert = UIAlertController(
            title: Strings.Localizable.Rename.ConfirmationAlert.title,
            message: Strings.Localizable.Rename.ConfirmationAlert.description,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: Strings.Localizable.cancel, style: .cancel) { _ in
            vc.dismiss(animated: true)
        }
        alert.addAction(cancelAction)
        
        let confirmAction = UIAlertAction(title: Strings.Localizable.Rename.ConfirmationAlert.ok, style: .default) { _ in
            completion()
        }
        alert.addAction(confirmAction)
        
        vc.present(alert, animated: true)
    }
    
    @MainActor
    @objc func textFieldChanged(_ textField: UITextField) {
        guard let renameAlertController = UIApplication.mnz_visibleViewController() as? UIAlertController,
              let textFieldText = textField.text else { return }
        
        let newName = textFieldText as NSString
        let isNewNameWithoutExtension = !newName.contains(".") || newName.pathExtension.mnz_isEmpty()
        var newNameIsEmpty = false
        newNameIsEmpty = textFieldText.formatted(.filePath(extensionStyle: nil)) == ""
        
        var enableRightButton = false

        if self.isFile() || self.isFolder() {
            let containsInvalidCharacters = newName.mnz_containsInvalidChars()
            enableRightButton = !(newName == "" ||
                                  newName.mnz_isEmpty() ||
                                  containsInvalidCharacters ||
                                  (self.isFile() && newNameIsEmpty) ||
                                  (self.isFile() && isNewNameWithoutExtension)
            )
            
            if isNewNameWithoutExtension, let name = self.name, self.isFile() {
                renameAlertController.title = Strings.Localizable.Rename.fileWithoutExtension((name as NSString).pathExtension)
                renameAlertController.textFields?.first?.textColor = UIColor.systemRed
                
                let textFieldView = renameAlertController.textFields?.first?.superview
                textFieldView?.layer.borderWidth = 1
                textFieldView?.layer.borderColor = UIColor.systemRed.cgColor
            } else {
                renameAlertController.title = self.fileFolderRenameAlertTitle(invalidChars: containsInvalidCharacters)
                renameAlertController.textFields?.first?.superview?.layer.borderWidth = 0
                textField.textColor = containsInvalidCharacters ? UIColor.systemRed : UIColor.label
            }
        }
        
        renameAlertController.actions.last?.isEnabled = enableRightButton
    }
}
