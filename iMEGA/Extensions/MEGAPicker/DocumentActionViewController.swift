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
        guard actionIdentifier == PickerConstant.openAction, let itemIdentifier = itemIdentifiers.first else {
            failRequest()
            return
        }
        Task {
            let providerIdentifier = await providerIdentifier(of: itemIdentifier) ?? itemIdentifier
            guard let url = URL(string: "mega://presentNode/\(providerIdentifier.rawValue)") else {
                failRequest()
                return
            }
            _ = await extensionContext.open(url)
            extensionContext.completeRequest()
        }
    }

    /// The File Provider extension's identifier of an item Files passes. A replicated domain passes the system's
    /// identifiers instead, such as `__fp/fs/docID(2596)`, mapped back here through the item's location on disk.
    /// `nil` for the legacy extension, which has no registered domain and passes the extension's identifiers.
    private func providerIdentifier(of itemIdentifier: NSFileProviderItemIdentifier) async -> NSFileProviderItemIdentifier? {
        guard let domainIdentifier = extensionContext.domainIdentifier else { return nil }
        do {
            let domains = try await NSFileProviderManager.domains()
            guard let domain = domains.first(where: { $0.identifier == domainIdentifier }),
                  let manager = NSFileProviderManager(for: domain) else {
                return nil
            }
            let url = try await manager.getUserVisibleURL(for: itemIdentifier)
            let (identifier, _) = try await NSFileProviderManager.identifierForUserVisibleFile(at: url)
            return identifier
        } catch {
            return nil
        }
    }

    private func failRequest() {
        let error = NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.failed.rawValue), userInfo: nil)
        extensionContext.cancelRequest(withError: error)
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        extensionContext.cancelRequest(withError: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
    }
}
