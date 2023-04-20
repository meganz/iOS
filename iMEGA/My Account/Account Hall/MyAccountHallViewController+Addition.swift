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
    
    @objc func setupNavigationBarColor(with trait: UITraitCollection) {
        let color: UIColor
        switch trait.theme {
        case .light:
            color = Colors.General.White.f7F7F7.color
        case .dark:
            color = Colors.General.Black._161616.color
        }
        
        navigationController?.navigationBar.standardAppearance.backgroundColor = color
        navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = color
        navigationController?.navigationBar.isTranslucent = false
    }
}
