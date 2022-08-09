import Foundation

extension CustomModalAlertViewController {
    
    func configureForBusinessGracePeriod() {
        image = Asset.Images.Business.paymentOverdue.image
        viewTitle = Strings.Localizable.somethingWentWrong
        detail = Strings.Localizable.ThereHasBeenAProblemWithYourLastPayment.pleaseAccessMEGAUsingADesktopBrowserForMoreInformation
        
        dismissButtonTitle = Strings.Localizable.dismiss
        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
                    return
                }
                if (rootViewController.isKind(of: MainTabBarController.self) == false) &&
                    (rootViewController.isKind(of: InitialLaunchViewController.self) == false) {
                    (UIApplication.shared.delegate as? AppDelegate)?.showMainTabBar()
                }
            })
        }
    }
}

