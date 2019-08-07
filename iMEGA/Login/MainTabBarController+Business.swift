
import Foundation

public extension MainTabBarController {
    @objc func showPaymentOverdueIfNeeded () {
        if MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount && MEGASdkManager.sharedMEGASdk().businessStatus == .gracePeriod {
            let customModalAlertVC = CustomModalAlertViewController ()
            customModalAlertVC.modalPresentationStyle = .overFullScreen
            customModalAlertVC.image = UIImage(named: "paymentOverdue")
            customModalAlertVC.viewTitle = NSLocalizedString("Something went wrong", comment: "")
            customModalAlertVC.detail = NSLocalizedString("There has been a problem with your last payment. Please access MEGA in a desktop browser for more information.", comment: "When logging in during the grace period, the administrator of the Business account will be notified that their payment is overdue, indicating that they need to access MEGA using a desktop browser for more information")
            customModalAlertVC.dismissButtonTitle = NSLocalizedString("dismiss", comment: "")
            
            UIApplication.mnz_presentingViewController()?.present(customModalAlertVC, animated: true, completion: nil)
        }
    }
}
