import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

extension MEGAQueryRecoveryLinkRequestDelegate {
    @objc func checkRecoveryKey(
        _ recoveryKey: String,
        link: String,
        completion: @escaping (Bool) -> Void
    ) {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        Task { @MainActor in
            do {
                try await accountUseCase.checkRecoveryKey(recoveryKey, link: link)
                completion(true)
            } catch let error as AccountErrorEntity {
                showAlertError(
                    message: error == .invalid ? Strings.Localizable.RecoveryKey.Error.Alert.Message.invalidKey : Strings.Localizable.somethingWentWrong
                )
                completion(false)
            } catch {
                showAlertError(message: Strings.Localizable.somethingWentWrong)
                completion(false)
            }
        }
    }
    
    private func showAlertError(message: String) {
        let alert = UIAlertController(
            title: Strings.Localizable.RecoveryKey.Error.Alert.title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: Strings.Localizable.ok, style: .cancel, handler: nil)
        )
        UIApplication.mnz_presentingViewController().present(alert, animated: true, completion: nil)
    }
}
