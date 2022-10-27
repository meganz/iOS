import Foundation

extension MyAccountHallViewController {
    
    @objc func showSettings() {
        let settingRouter = SettingViewRouter(presenter: navigationController)
        settingRouter.start()
    }
    
    @objc func configNavigationItem() {
        guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
            buyPROBarButtonItem?.title = Strings.Localizable.upgrade
            accountTypeLabel?.text = ""
            return
        }
        
        switch accountDetails.type {
        case .business:
            navigationItem.rightBarButtonItem = nil
            accountTypeLabel?.text = Strings.Localizable.business
        case .proFlexi:
            navigationItem.rightBarButtonItem = nil
            accountTypeLabel?.text = MEGAAccountDetails.string(for: accountDetails.type)
        default:
            buyPROBarButtonItem?.title = Strings.Localizable.upgrade
            accountTypeLabel?.text = ""
        }
    }
}
