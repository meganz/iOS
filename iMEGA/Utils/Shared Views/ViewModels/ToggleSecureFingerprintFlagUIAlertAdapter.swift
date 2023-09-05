import MEGAL10n
import MEGASDKRepo

struct ToggleSecureFingerprintFlagUIAlertAdapter {
    let manager: any SecureFingerprintManagerProtocol
    
    func showAlert() {
        let alertController = UIAlertController(title: nil,
                                                message: "Mandatory Contact Fingerprint Verification \(manager.secureFingerprintStatus())",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.localized("ok", comment: ""),
                                                style: .cancel,
                                                handler: nil))
        UIApplication.mnz_visibleViewController().present(alertController, animated: true)
    }
}
