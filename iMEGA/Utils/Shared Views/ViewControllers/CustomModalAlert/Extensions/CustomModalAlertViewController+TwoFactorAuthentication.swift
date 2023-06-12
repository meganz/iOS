import Foundation

extension CustomModalAlertViewController {
    @objc func configureForTwoFactorAuthentication(requestedByUser: Bool) {
        image = Asset.Images.TwoFactorAuthentication._2FASetup.image
        viewTitle = Strings.Localizable.whyYouDoNeedTwoFactorAuthentication
        detail = Strings.Localizable.whyYouDoNeedTwoFactorAuthenticationDescription
        firstButtonTitle = Strings.Localizable.beginSetup
        
        if requestedByUser {
            dismissButtonTitle = Strings.Localizable.cancel
        } else {
            dismissButtonTitle = Strings.Localizable.notNow
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
                    enablingTwoFactorAuthenticationVC.seed = request.text // Returns the Base32 secret code needed to configure multi-factor authentication.
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
