import Foundation
import MEGASwiftUI

extension MyAccountHallViewController {
    
    @objc func showSettings() {
        let settingRouter = SettingViewRouter(presenter: navigationController)
        settingRouter.start()
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
    
    @objc func setUpInvokeCommands() {
        viewModel.invokeCommand = { [weak self] command in
            guard let self else { return }
            
            excuteCommand(command)
        }
    }
    
    @objc func loadContent() {
        viewModel.dispatch(.reloadUI)
        viewModel.dispatch(.load(.planList))
        viewModel.dispatch(.load(.accountDetails))
        viewModel.dispatch(.load(.contentCounts))
    }
    
    @objc func addSubscriptions() {
        viewModel.dispatch(.addSubscriptions)
    }
    
    @objc func removeSubscriptions() {
        viewModel.dispatch(.removeSubscriptions)
    }
    
    // MARK: - Feature flag
    
    @objc func isNewUpgradeAccountPlanFeatureFlagEnabled() -> Bool {
        viewModel.isNewUpgradeAccountPlanEnabled()
    }
    
    // MARK: - Open sections programmatically
    @objc func openAchievements() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let achievementsIndexPath = IndexPath(row: MyAccountMegaSection.achievements.rawValue, section: MyAccountSection.mega.rawValue)
            if let tableView = self.tableView {
                tableView.selectRow(at: achievementsIndexPath, animated: true, scrollPosition: .none)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: achievementsIndexPath)
            }
        }
    }
    
    @objc func openOffline() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let offlineIndexPath = IndexPath(row: MyAccountMegaSection.offline.rawValue, section: MyAccountSection.mega.rawValue)
            if let tableView = self.tableView {
                tableView.selectRow(at: offlineIndexPath, animated: true, scrollPosition: .none)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: offlineIndexPath)
            }
        }
    }
    
    // MARK: - Private
    
    private func excuteCommand(_ command: AccountHallViewModel.Command) {
        switch command {
        case .reloadCounts:
            tableView?.reloadData()
        case .reloadUIContent:
            configNavigationBar()
            configPlanDisplay()
            configTableFooterView()
            setUserAvatar()
            setUserFullName()
            tableView?.reloadData()
        case .setUserAvatar:
            setUserAvatar()
        case .setName:
            setUserFullName()
        case .configPlanDisplay:
            configPlanDisplay()
        }
    }
    
    private func setUserAvatar() {
        guard let userHandle = viewModel.currentUserHandle else { return }
        avatarImageView?.mnz_setImage(forUserHandle: userHandle)
    }
    
    private func setUserFullName() {
        nameLabel?.text = viewModel.userFullName
    }
    
    private func configPlanDisplay() {
        accountTypeLabel?.text = ""
        buyPROBarButtonItem?.title = nil
        buyPROBarButtonItem?.isEnabled = false

        guard !viewModel.isNewUpgradeAccountPlanEnabled(),
              let accountDetails = viewModel.accountDetails else {
            return
        }
        
        switch accountDetails.proLevel {
        case .business, .proFlexi:
            navigationItem.rightBarButtonItem = nil
            accountTypeLabel?.text = accountDetails.proLevel.toAccountTypeDisplayName()
            buyPROBarButtonItem?.title = nil
            buyPROBarButtonItem?.isEnabled = false
        default:
            accountTypeLabel?.text = ""
            buyPROBarButtonItem?.title = Strings.Localizable.upgrade
            buyPROBarButtonItem?.isEnabled = !viewModel.planList.isEmpty
        }
    }
    
    private func configNavigationBar() {
        if let navigationController, navigationController.isNavigationBarHidden {
            navigationController.setNavigationBarHidden(false, animated: true)
        }
    }
    
    private func configTableFooterView() {
        guard viewModel.isMasterBusinessAccount else {
            tableView?.tableFooterView = UIView(frame: .zero)
            return
        }
        tableFooterLabel?.text = Strings.Localizable.userManagementIsOnlyAvailableFromADesktopWebBrowser
        tableView?.tableFooterView = tableFooterView
    }
}
