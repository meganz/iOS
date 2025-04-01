import MEGAAppPresentation
import MEGAL10n
import UIKit

class DeleteAccountRouter: Routing {
    
    private weak var presenter: UIViewController?
    private var deleteAccountAction: (() -> Void)?
    
    init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let alertController = UIAlertController(title: Strings.Localizable.youWillLooseAllData, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default) { [weak self] _ in
            self?.deleteAccountAction?()
            self?.deleteAccountAction = nil
        })
        return alertController
    }
    
    func start() {
        SVProgressHUD.show()
        getMultiFactorAuthenticationStatus { [weak self] status in
            SVProgressHUD.dismiss()
            guard let strongSelf = self else { return }
            strongSelf.setDeleteAccountAction(status)
            let vc = strongSelf.build()
            strongSelf.presenter?.present(vc, animated: true)
        }
    }
    
    private func setDeleteAccountAction(_ status: Bool) {
        if status {
            deleteAccountAction = deleteActionForTwoFactorAuthEnabled
        } else {
            deleteAccountAction = deleteActionForTwoFactorAuthDisabled
        }
    }
    
    private func deleteActionForTwoFactorAuthEnabled() {
        guard let twoFactorAuthenticationVC = UIStoryboard(name: "TwoFactorAuthentication", bundle: nil).instantiateViewController(withIdentifier: "TwoFactorAuthenticationViewControllerID") as? TwoFactorAuthenticationViewController else {
            return
        }
        guard let settingsVc = presenter as? SettingsTableViewController else { return }
        twoFactorAuthenticationVC.twoFAMode = .cancelAccount
        settingsVc.navigationController?.pushViewController(twoFactorAuthenticationVC, animated: true)
        NotificationCenter.default.addObserver(settingsVc, selector: #selector(settingsVc.showDeleteAccountEmailConfirmationView), name: .MEGAAwaitingEmailConfirmation, object: nil)
    }
    
    private func deleteActionForTwoFactorAuthDisabled() {
        guard let settingsVc = presenter as? SettingsTableViewController else { return }
        MEGASdk.shared.cancelAccount(with: settingsVc)
    }
    
    private func getMultiFactorAuthenticationStatus(completion: @escaping (Bool) -> Void) {
        guard MEGAReachabilityManager.isReachable() else { return }
        guard let myEmail = MEGASdk.currentUserEmail else { return }
        MEGASdk.shared
            .multiFactorAuthCheck(withEmail: myEmail,
                                  delegate: MEGAMultiFactorAuthCheckRequestDelegate { (request, _) in
                guard let authRequest = request else { return }
                completion(authRequest.flag)
            })
    }
}
