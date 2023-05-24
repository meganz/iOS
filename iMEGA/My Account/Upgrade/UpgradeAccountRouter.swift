
import Foundation

final class UpgradeAccountRouter: NSObject {
    @objc func pushUpgradeTVC(navigationController: UINavigationController) {
        if MEGASdkManager.sharedMEGASdk().mnz_accountDetails != nil && (MEGAPurchase.sharedInstance()?.products?.count ?? 0 > 0) {
            let upgradeTVC = UpgradeAccountFactory().createUpgradeAccountTVC()
            navigationController.pushViewController(upgradeTVC, animated: true)
        } else {
            MEGAReachabilityManager.isReachableHUDIfNot()
        }
    }
    
    @objc func presentUpgradeTVC() {
        if MEGASdkManager.sharedMEGASdk().mnz_accountDetails != nil && MEGAPurchase.sharedInstance()?.products?.count ?? 0 > 0 {
            let upgradeAccountNC = UpgradeAccountFactory().createUpgradeAccountNC()
            
            UIApplication.mnz_visibleViewController().present(upgradeAccountNC, animated: true, completion: nil)
        } else {
            MEGAReachabilityManager.isReachableHUDIfNot()
        }
    }
    
    @objc func presentChooseAccountType() {
        if MEGASdkManager.sharedMEGASdk().mnz_accountDetails != nil && MEGAPurchase.sharedInstance()?.products?.count ?? 0 > 0 {
            let upgradeAccountNC = UpgradeAccountFactory().createUpgradeAccountChooseAccountType()
            
            UIApplication.mnz_visibleViewController().present(upgradeAccountNC, animated: true, completion: nil)
        } else {
            MEGAReachabilityManager.isReachableHUDIfNot()
        }
    }
}
