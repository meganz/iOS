import Foundation
import MEGAData
import MEGASdk
import MEGASwift

extension MEGANode {
    
    /// Check whether the receiver is a child node of a given node or equal to that node.
    /// - Parameters:
    ///   - node: The `MEGANode` to check against the receiver.
    ///   - sdk: `MEGASdk` instance which manages both the receiver and the given node.
    /// - Returns: true if the receiver is an immediate or distant child node of the passed node or if passed node is equal to the receiver; otherwise false.
    @objc func isDescendant(of node: MEGANode, in sdk: MEGASdk) -> Bool {
        guard node.handle != handle else {
            return true
        }
        
        guard let parent = sdk.parentNode(for: self) else {
            return false
        }
        
        if parent.handle == node.handle {
            return true
        } else {
            return parent.isDescendant(of: node, in: sdk)
        }
    }
    
    /// Check whether the receiver is a child node of an unverified shared folder node.
    /// - Parameters:
    ///   - email: The email of the receiver's owner.
    ///   - sdk: `MEGASdk` instance which manages receiver's owner.
    /// - Returns: true if the node's `isNodeKeyDecrypted` is false and user has not yet verified the owner; otherwise false.
    @objc func isUndecrypted(ownerEmail email: String, in sdk: MEGASdk) -> Bool {
        guard let owner = sdk.contact(forEmail: email),
              !self.isNodeKeyDecrypted() else {
            return false
        }
        return !sdk.areCredentialsVerified(of: owner)
    }
    
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
    
    @objc func mnz_renameNode(_ newName: String, completion: ((MEGARequest) -> Void)?) {
        MEGASdk.shared.renameNode(
            self,
            newName: newName,
            delegate: RequestDelegate(completion: { result in
                switch result {
                case .success(let request):
                    completion?(request)
                case .failure:
                    break
                }
            })
        )
    }
    
    @objc func textFieldChanged(_ textField: UITextField) {
        guard let renameAlertController = UIApplication.mnz_visibleViewController() as? UIAlertController,
              let textFieldText = textField.text else { return }
        
        let newName = textFieldText as NSString
        let isNewNameWithoutExtension = !newName.contains(".") || newName.pathExtension.mnz_isEmpty()
        var newNameIsEmpty = false
        if #available(iOS 15.0, *) {
            newNameIsEmpty = textFieldText.formatted(.filePath(extensionStyle: nil)) == ""
        } else {
            newNameIsEmpty = FileExtension.FormatStyle(extensionStyle: nil).format(textFieldText) == ""
        }
        
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
                renameAlertController.textFields?.first?.textColor = UIColor.mnz_redError()
                
                let textFieldView = renameAlertController.textFields?.first?.superview
                textFieldView?.layer.borderWidth = 1
                textFieldView?.layer.borderColor = UIColor.mnz_redError().cgColor
            } else {
                renameAlertController.title = self.fileFolderRenameAlertTitle(invalidChars: containsInvalidCharacters)
                renameAlertController.textFields?.first?.superview?.layer.borderWidth = 0
                textField.textColor = containsInvalidCharacters ? UIColor.mnz_redError() : UIColor.mnz_label()
            }
        }
        
        renameAlertController.actions.last?.isEnabled = enableRightButton
    }
}
