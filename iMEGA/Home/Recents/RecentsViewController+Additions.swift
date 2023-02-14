
extension RecentsViewController {
    
    @objc func showContactVerificationView(forUserEmail userEmail: String) {
        guard let user = MEGASdkManager.sharedMEGASdk().contact(forEmail: userEmail),
              let verifyCredentialsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "VerifyCredentialsViewControllerID") as? VerifyCredentialsViewController else {
            return
        }
        
        verifyCredentialsVC.user = user
        verifyCredentialsVC.userName = user.mnz_displayName ?? user.email
        verifyCredentialsVC.setContactVerificationWithIncomingSharedItem(true, isShowIncomingItemWarningView: false)
        verifyCredentialsVC.statusUpdateCompletionBlock = { [weak self] in
            self?.reloadUI()
        }
        
        let navigationController = MEGANavigationController(rootViewController: verifyCredentialsVC)
        navigationController.addRightCancelButton()
        self.present(navigationController, animated: true)
    }
}
