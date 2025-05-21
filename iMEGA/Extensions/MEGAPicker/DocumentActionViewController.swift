import FileProviderUI
import MEGAAssets
import MEGAL10n
import UIKit

final class DocumentActionViewController: FPUIActionExtensionViewController {
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    
    override func viewDidLoad() {
        logoImageView.image = MEGAAssets.UIImage.image(named: "splashScreenMEGALogo")
        cancelBarButtonItem?.title = Strings.Localizable.cancel
        titleLabel?.text = Strings.Localizable.pleaseLogInToYourAccount
        messageLabel?.text = Strings.Localizable.openMEGAAndSignInToContinue
    }
    
    override func prepare(forError error: any Error) {
        let nsError = error as NSError
        if nsError.userInfo[PickerConstant.passcodeEnabled] != nil {
            titleLabel?.text = Strings.Localizable.Picker.Disable.Passcode.title
            messageLabel.text = Strings.Localizable.Picker.Disable.Passcode.description
        }
    }

    override func prepare(forAction actionIdentifier: String, itemIdentifiers: [NSFileProviderItemIdentifier]) {
        guard
            actionIdentifier == PickerConstant.openAction,
            let itemIdentifier = itemIdentifiers.first,
            let url = URL(string: "mega://presentNode/\(itemIdentifier.rawValue)")
        else {
            let error = NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.failed.rawValue), userInfo: nil)
            extensionContext.cancelRequest(withError: error)
            return
        }
        
        extensionContext.open(url) { [weak self] _ in
            Task { @MainActor in
                self?.extensionContext.completeRequest()
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        extensionContext.cancelRequest(withError: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
    }
}
