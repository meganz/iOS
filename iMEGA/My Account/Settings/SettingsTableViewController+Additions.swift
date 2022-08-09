
extension SettingsTableViewController {
    @objc func presentCallsSettings() {
        guard let navigationController = navigationController else { return }
        CallsSettingsViewRouter(presenter: navigationController).start()
    }
    
    @objc func showQASettingsView() {
        guard let navigationController = navigationController else { return }
        QASettingsRouter(navigationController: navigationController).start()
    }

    //MARK: - Delete account
    private func getMultiFactorAuthenticationStatus(completion: @escaping (Bool) -> Void) {
        guard let myEmail = MEGASdkManager.sharedMEGASdk().myEmail else { return }
        MEGASdkManager.sharedMEGASdk()
            .multiFactorAuthCheck(
                withEmail: myEmail,
                delegate: MEGAMultiFactorAuthCheckRequestDelegate { (request, error) in
                    guard let authRequest = request else { return }
                    completion(authRequest.flag)
                })
    }
  
    @objc func showDeleteAccountEmailConfirmationView() {
        NotificationCenter.default.removeObserver(self, name: .MEGAAwaitingEmailConfirmation, object: nil)
        
        let awaitingEmailConfirmationView = AwaitingEmailConfirmationView.instanceFromNib
        awaitingEmailConfirmationView.titleLabel.text = Strings.Localizable.awaitingEmailConfirmation
        awaitingEmailConfirmationView.descriptionLabel.text = Strings.Localizable.ifYouCantAccessYourEmailAccount
        awaitingEmailConfirmationView.frame = self.view.bounds
        self.view = awaitingEmailConfirmationView
    }
    
    @objc func showDeleteAccountAlert() {
        SVProgressHUD.show()
        getMultiFactorAuthenticationStatus { [weak self] status in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            self.showDeleteAccountAlert(withTwoFactorAuthStatus: status)
        }
    }
    
    private func showDeleteAccountAlert(withTwoFactorAuthStatus isTwoFactorAuthEnabled: Bool) {
        guard MEGAReachabilityManager.isReachable() else { return }
        
        let alertController = UIAlertController(title: Strings.Localizable.youWillLooseAllData, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            if isTwoFactorAuthEnabled {
                guard let twoFactorAuthenticationVC = UIStoryboard(name: "TwoFactorAuthentication", bundle: nil).instantiateViewController(withIdentifier: "TwoFactorAuthenticationViewControllerID") as? TwoFactorAuthenticationViewController else {
                    return
                }
                twoFactorAuthenticationVC.twoFAMode = .cancelAccount
                self.navigationController?.pushViewController(twoFactorAuthenticationVC, animated: true)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.showDeleteAccountEmailConfirmationView), name: .MEGAAwaitingEmailConfirmation, object: nil)
            } else {
                MEGASdkManager.sharedMEGASdk().cancelAccount(with: self)
            }
        })
        
        present(alertController, animated: true)
    }
}

//MARK: - MEGARequestDelegate
extension SettingsTableViewController: MEGARequestDelegate {
    public func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        switch request.type {
        case .MEGARequestTypeGetCancelLink:
            guard error.type == .apiOk else { return }
            showDeleteAccountEmailConfirmationView()
        default:
            return
        }
    }
}
