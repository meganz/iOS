import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

extension CustomModalAlertViewController {
    func configureForUpgradeSecurity() {
        image = UIImage.accountUpgradeSecurity
        viewTitle = Strings.Localizable.Account.UpgradeSecurity.title
        detail = Strings.Localizable.Account.UpgradeSecurity.Message.upgrade
        
        firstButtonTitle = Strings.Localizable.Account.UpgradeSecurity.Button.title
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                Task.detached { @MainActor in
                    do {
                        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
                        _ = try await accountUseCase.upgradeSecurity()
                    } catch {
                        SVProgressHUD.showError(withStatus: error.localizedDescription)
                    }
                }
            })
        }
        
        isShowCloseButton = true
        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
