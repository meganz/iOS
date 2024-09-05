import Foundation

final class UpgradeAccountFactory: NSObject {
    
    @objc func createUpgradeAccountTVC() -> UpgradeTableViewController {
        
        guard let upgradeTVC = UIStoryboard(name: "UpgradeAccount", bundle: nil).instantiateViewController(withIdentifier: "UpgradeTableViewControllerID") as? UpgradeTableViewController else {
            fatalError("Could not instantiate UpgradeTableViewController")
        }
        
        return upgradeTVC
    }
    
    @objc func createUpgradeAccountNC() -> MEGANavigationController {
        let upgradeAccountNC = MEGANavigationController.init(rootViewController: createUpgradeAccountTVC())
        
        return upgradeAccountNC
    }
    
    @objc func createUpgradeAccountChooseAccountType(accountBaseStorage: Int) -> MEGANavigationController {
        let upgradeAccountNC = createUpgradeAccountNC()
        upgradeAccountNC.modalPresentationStyle = .fullScreen
        
        guard let upgradeTVC = upgradeAccountNC.viewControllers.first as? UpgradeTableViewController else {
            fatalError("Could not access UpgradeTableViewController")
        }
        upgradeTVC.isChoosingTheAccountType = true
        upgradeTVC.accountBaseStorage = accountBaseStorage as NSNumber
        
        return upgradeAccountNC
    }
}
