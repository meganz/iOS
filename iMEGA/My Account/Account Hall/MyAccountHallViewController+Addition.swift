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

    @objc func registerCustomCells() {
        self.tableView?.register(HostingTableViewCell<MyAccountHallPlanView>.self,
                                 forCellReuseIdentifier: "AccountPlanUpgradeCell")
    }
    
    //MARK: - Feature flag
    
    @objc func isNewUpgradeAccountPlanFeatureFlagEnabled() -> Bool {
        FeatureFlagProvider().isFeatureFlagEnabled(for: .newUpgradeAccountPlanUI)
    }
    
    //MARK: - Open sections programmatically
    @objc func openAchievements() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let achievementsIndexPath = self.calculateIndexPath(for: MyAccountMegaSection.achievements.rawValue, in: MyAccountSection.mega.rawValue)
            if let tableView = self.tableView {
                tableView.selectRow(at: achievementsIndexPath, animated: true, scrollPosition: .none)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: achievementsIndexPath)
            }
        }
    }
    
    @objc func openOffline() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let offlineIndexPath = self.calculateIndexPath(for: MyAccountMegaSection.offline.rawValue, in: MyAccountSection.mega.rawValue)
            if let tableView = self.tableView {
                tableView.selectRow(at: offlineIndexPath, animated: true, scrollPosition: .none)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: offlineIndexPath)
            }
        }
    }
}
