import UIKit

let maxCharactersAllowedForChatTitle = 30

@objc final class EnterGroupNameTextFieldDelegate: NSObject, UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text else {
            return false
        }
        if string == "" {
            return true
        }
        return textFieldText.lengthOfBytes(using: String.Encoding.utf8) <= maxCharactersAllowedForChatTitle
    }
}
