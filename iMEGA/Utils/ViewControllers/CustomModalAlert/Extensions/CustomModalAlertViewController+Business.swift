import Foundation

extension CustomModalAlertViewController {
    
    func configureForBusinessGracePeriod() {
        image = UIImage(named: "paymentOverdue")
        viewTitle = NSLocalizedString("Something went wrong", comment: "")
        detail = NSLocalizedString("There has been a problem with your last payment. Please access MEGA using a desktop browser for more information.", comment: "When logging in during the grace period, the administrator of the Business account will be notified that their payment is overdue, indicating that they need to access MEGA using a desktop browser for more information")
        
        dismissButtonTitle = NSLocalizedString("dismiss", comment: "Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).")
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

