import UIKit
import FileProviderUI

final class DocumentActionViewController: FPUIActionExtensionViewController {
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func viewDidLoad() {
        cancelBarButtonItem?.title = Strings.Localizable.cancel
        titleLabel?.text = Strings.Localizable.pleaseLogInToYourAccount
        messageLabel?.text = Strings.Localizable.openMEGAAndSignInToContinue
    }
    
    override func prepare(forError error: Error) {
        let nsError = error as NSError
        if nsError.userInfo[PickerConstant.passcodeEnabled] != nil {
            titleLabel?.text = Strings.Localizable.Picker.Disable.Passcode.title
            messageLabel.text = Strings.Localizable.Picker.Disable.Passcode.description
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        extensionContext.cancelRequest(withError: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
    }
}
