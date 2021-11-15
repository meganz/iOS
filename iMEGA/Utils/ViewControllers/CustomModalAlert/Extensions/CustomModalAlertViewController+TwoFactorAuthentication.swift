import Foundation

extension CustomModalAlertViewController {
    @objc func configureForTwoFactorAuthentication(requestedByUser: Bool) {
        image = UIImage(named: "2FASetup")
        viewTitle = NSLocalizedString("whyYouDoNeedTwoFactorAuthentication", comment: "Title shown when you start the process to enable Two-Factor Authentication")
        detail = NSLocalizedString("whyYouDoNeedTwoFactorAuthenticationDescription", comment: "Description text of the dialog displayed to start setup the Two-Factor Authentication")
        firstButtonTitle = NSLocalizedString("beginSetup", comment: "Button title to start the setup of a feature. For example 'Begin Setup' for Two-Factor Authentication")
        if requestedByUser {
            dismissButtonTitle = NSLocalizedString("cancel", comment: "")
        } else {
            dismissButtonTitle = NSLocalizedString("notNow", comment: "Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.")
        }

        firstCompletion = { [weak self] in
            self?.dismiss(animated: true) {
                SVProgressHUD.show()
                MEGASdkManager.sharedMEGASdk().multiFactorAuthGetCode(with: MEGAGenericRequestDelegate.init(completion: { (request, error) in
                    if error.type != .apiOk {
                        SVProgressHUD.showError(withStatus: NSLocalizedString(error.name, comment: ""))
                        return
                    }

                    SVProgressHUD.dismiss()
                    let enablingTwoFactorAuthenticationVC = UIStoryboard(name: "TwoFactorAuthentication", bundle: nil).instantiateViewController(withIdentifier: "EnablingTwoFactorAuthenticationViewControllerID") as! EnablingTwoFactorAuthenticationViewController
                    enablingTwoFactorAuthenticationVC.seed = request.text //Returns the Base32 secret code needed to configure multi-factor authentication.
                    enablingTwoFactorAuthenticationVC.hidesBottomBarWhenPushed = true
                    
                    UIApplication.mnz_visibleViewController().navigationController?.pushViewController(enablingTwoFactorAuthenticationVC, animated: true)
                }))
            }
        }

        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
