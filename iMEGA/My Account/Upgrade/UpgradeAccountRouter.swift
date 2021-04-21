
import Foundation

final class UpgradeAccountRouter: NSObject {
    @objc func pushUpgradeTVC(navigationController: UINavigationController) {
        if (MEGASdkManager.sharedMEGASdk().mnz_accountDetails != nil && (MEGAPurchase.sharedInstance()?.products?.count ?? 0 > 0)) { //Only mnz_accountDetails in Obj-C
            let upgradeTVC = UpgradeAccountFactory().createUpgradeAccountTVC()
            navigationController.pushViewController(upgradeTVC, animated: true)
        } else {
            MEGAReachabilityManager.isReachableHUDIfNot()
        }
    }
    
    @objc func presentUpgradeTVC() {
        if (MEGASdkManager.sharedMEGASdk().mnz_accountDetails != nil && (MEGAPurchase.sharedInstance()?.products?.count ?? 0 > 0)) { //Only mnz_accountDetails in Obj-C
            let upgradeAccountNC = UpgradeAccountFactory().createUpgradeAccountNC()
            
            UIApplication.mnz_visibleViewController().present(upgradeAccountNC, animated: true, completion: nil)
        } else {
            MEGAReachabilityManager.isReachableHUDIfNot()
        }
    }
    
    @objc func presentChooseAccountType() {
        if (MEGASdkManager.sharedMEGASdk().mnz_accountDetails != nil && (MEGAPurchase.sharedInstance()?.products?.count ?? 0 > 0)) { //This was not present on the Obj-C code
            let upgradeAccountNC = UpgradeAccountFactory().createUpgradeAccountChooseAccountType()
            
            UIApplication.mnz_visibleViewController().present(upgradeAccountNC, animated: true, completion: nil)
        } else {
            MEGAReachabilityManager.isReachableHUDIfNot()
        }
    }
}
