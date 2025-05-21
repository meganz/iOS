import Foundation
import MEGAAppSDKRepo
import MEGAAssets
import MEGAL10n

extension CustomModalAlertViewController {
    @objc func configureForTwoFactorAuthentication(requestedByUser: Bool) {
        image = MEGAAssets.UIImage._2FASetup
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
                MEGASdk.shared.multiFactorAuthGetCode(with: RequestDelegate { result in
                    guard case let .success(request) = result else {
                        if case let .failure(error) = result {
                            SVProgressHUD.showError(withStatus: Strings.localized(error.name, comment: ""))
                        }
                        return
                    }

                    SVProgressHUD.dismiss()
                    let enablingTwoFactorAuthenticationVC = UIStoryboard(name: "TwoFactorAuthentication", bundle: nil).instantiateViewController(withIdentifier: "EnablingTwoFactorAuthenticationViewControllerID") as! EnablingTwoFactorAuthenticationViewController
                    enablingTwoFactorAuthenticationVC.seed = request.text // Returns the Base32 secret code needed to configure multi-factor authentication.
                    enablingTwoFactorAuthenticationVC.hidesBottomBarWhenPushed = true
                    
                    UIApplication.mnz_visibleViewController().navigationController?.pushViewController(enablingTwoFactorAuthenticationVC, animated: true)
                })
            }
        }

        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
