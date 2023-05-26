import MEGASwiftUI

@objc enum MyAccountSection: Int, CaseIterable {
    case mega = 0, other
}

@objc enum MyAccountMegaSection: Int, CaseIterable {
    case plan = 0, storage, contacts, backups, notifications, achievements, transfers, offline, rubbishBin
}

@objc enum MyAccountOtherSection: Int, CaseIterable {
    case settings
}

extension MyAccountHallViewController: UITableViewDataSource {
    //MARK: - Settings row setup data
    private func settingsSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.settingsTitle,
                              icon: Asset.Images.MyAccount.iconSettings.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    //MARK: - Storage row setup data for Business and Pro Flexi accounts
    private func storageBusinessAccountSetupData() -> MyAccountHallCellData {
        let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails
        return MyAccountHallCellData(sectionText: Strings.Localizable.storage,
                                     storageText: Strings.Localizable.storage,
                                     transferText: Strings.Localizable.transfer,
                                     storageUsedText: NSString.mnz_formatString(fromByteCountFormatter: String.memoryStyleString(fromByteCount: accountDetails?.storageUsed.int64Value ?? 0)),
                                     transferUsedText: NSString.mnz_formatString(fromByteCountFormatter: String.memoryStyleString(fromByteCount: accountDetails?.transferOwnUsed.int64Value ?? 0)))
    }
    
    //MARK: - Storage row setup data
    private func storageSetupData() -> MyAccountHallCellData {
        let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails
        let detailText = String(format: "%@ / %@",
                                NSString.mnz_formatString(fromByteCountFormatter: String.memoryStyleString(fromByteCount: accountDetails?.storageUsed.int64Value ?? 0)),
                                NSString.mnz_formatString(fromByteCountFormatter: String.memoryStyleString(fromByteCount: accountDetails?.storageMax.int64Value ?? 0)))
        
        return MyAccountHallCellData(sectionText: Strings.Localizable.storage,
                                     detailText: detailText,
                                     icon: Asset.Images.MyAccount.iconStorage.image.imageFlippedForRightToLeftLayoutDirection())
    }
    
    //MARK: - Contacts row setup data
    private func contactsSetupData(existsPendingView: Bool) -> MyAccountHallCellData {
        var isPendingViewVisible = false
        var pendingText = ""
        let incomingContacts = viewModel.incomingContactRequestsCount
        
        if existsPendingView && incomingContacts != 0 {
            isPendingViewVisible = true
            pendingText = String(describing: incomingContacts)
        }
        return MyAccountHallCellData(sectionText: Strings.Localizable.contactsTitle,
                                     icon: Asset.Images.MyAccount.iconContacts.image.imageFlippedForRightToLeftLayoutDirection(),
                                     isPendingViewVisible: isPendingViewVisible,
                                     pendingText: pendingText)
    }
    
    //MARK: - Notifications row setup data
    private func notificationsSetupData(existsPendingView: Bool) -> MyAccountHallCellData {
        var isPendingViewVisible = false
        var pendingText = ""
        
        let unseenUserAlerts = viewModel.relevantUnseenUserAlertsCount
        
        if existsPendingView && unseenUserAlerts != 0 {
            isPendingViewVisible = true
            pendingText = String(describing: unseenUserAlerts)
        }
        
        return MyAccountHallCellData(sectionText: Strings.Localizable.notifications,
                                     icon: Asset.Images.MyAccount.iconNotifications.image.imageFlippedForRightToLeftLayoutDirection(),
                                     isPendingViewVisible: isPendingViewVisible,
                                     pendingText: pendingText)
    }
    
    //MARK: - Backups row setup data
    private func backupsSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.Backups.title,
                              icon: Asset.Images.MyAccount.backups.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    //MARK: - Achievements row setup data
    private func achievementsSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.achievementsTitle,
                              icon: Asset.Images.MyAccount.iconAchievements.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    //MARK: - Transfers row setup data
    private func transfersSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.transfers,
                              icon: Asset.Images.MyAccount.iconTransfers.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    //MARK: - Offline row setup data
    private func offlineSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.offline,
                              icon: Asset.Images.MyAccount.iconOffline.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    //MARK: - Rubbish Bin row setup data
    private func rubbishBinSetupData() -> MyAccountHallCellData {
        var rubbishBinSize = ""
        if let rubbishBinNode = MEGASdkManager.sharedMEGASdk().rubbishNode {
            rubbishBinSize = NSString.mnz_formatString(fromByteCountFormatter: Helper.size(for: rubbishBinNode, api: MEGASdkManager.sharedMEGASdk()))
        }
        
        return MyAccountHallCellData(sectionText: Strings.Localizable.rubbishBinLabel,
                                     detailText: rubbishBinSize,
                                     icon: Asset.Images.NodeActions.rubbishBin.image.imageFlippedForRightToLeftLayoutDirection(),
                                     isPendingViewVisible: true)
    }
    
    //MARK: - Upgrade Plan row setup
    private func upgradePlanSetupCell(_ indexPath: IndexPath) -> HostingTableViewCell<MyAccountHallPlanView> {
        guard let cell = tableView?.dequeueReusableCell(withIdentifier: "AccountPlanUpgradeCell", for: indexPath) as? HostingTableViewCell<MyAccountHallPlanView> else {
            return HostingTableViewCell<MyAccountHallPlanView>()
        }
        
        let upgradeCellView = MyAccountHallPlanView(viewModel: self.viewModel)
        cell.host(upgradeCellView, parent: self)
        cell.selectionStyle = .none
        return cell
    }
    
    //MARK: - Row Index
    private var showPlanRow: Bool {
        !MEGASdkManager.sharedMEGASdk().isAccountType(.business) && !MEGASdkManager.sharedMEGASdk().isAccountType(.proFlexi)
    }
    
    private var sectionRowCount: Int {
        guard isNewUpgradeAccountPlanFeatureFlagEnabled() else {
            return MyAccountMegaSection.allCases.count - 1
        }
        return showPlanRow ? MyAccountMegaSection.allCases.count : MyAccountMegaSection.allCases.count - 1
    }
    
    //MARK: - UITableView data source
    @objc func menuRowIndex(_ indexPath: IndexPath) -> Int {
        guard isNewUpgradeAccountPlanFeatureFlagEnabled() else {
            return indexPath.row + 1
        }
        return showPlanRow ? indexPath.row : indexPath.row + 1
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        MyAccountSection.allCases.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == MyAccountSection.mega.rawValue ? sectionRowCount : MyAccountOtherSection.allCases.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowIndex = menuRowIndex(indexPath)
        let isShowStorageUsageCell = (MEGASdkManager.sharedMEGASdk().isAccountType(.business) ||
                                      MEGASdkManager.sharedMEGASdk().isAccountType(.proFlexi)) &&
        rowIndex == MyAccountMegaSection.storage.rawValue &&
        indexPath.section == MyAccountSection.mega.rawValue
        let identifier = isShowStorageUsageCell ? "MyAccountHallStorageUsageTableViewCellID" : "MyAccountHallTableViewCellID"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MyAccountHallTableViewCell ?? MyAccountHallTableViewCell(style: .default, reuseIdentifier: identifier)
        
        if indexPath.section == MyAccountSection.other.rawValue {
            cell.setup(data: settingsSetupData())
            return cell
        }
        
        switch MyAccountMegaSection(rawValue: rowIndex) {
        case .plan: return upgradePlanSetupCell(indexPath)
        case .storage: cell.setup(data: isShowStorageUsageCell ? storageBusinessAccountSetupData() : storageSetupData())
        case .contacts: cell.setup(data: contactsSetupData(existsPendingView: cell.pendingView != nil))
        case .backups: cell.setup(data: backupsSetupData())
        case .notifications: cell.setup(data: notificationsSetupData(existsPendingView: cell.pendingView != nil))
        case .achievements: cell.setup(data: achievementsSetupData())
        case .transfers: cell.setup(data: transfersSetupData())
        case .offline: cell.setup(data: offlineSetupData())
        case .rubbishBin: cell.setup(data: rubbishBinSetupData())
        default: break
        }
        
        cell.sectionLabel.sizeToFit()
        
        return cell
    }
    
    func calculateIndexPath(for row: Int, in section: Int) -> IndexPath {
        if section == MyAccountSection.mega.rawValue &&
            (!isNewUpgradeAccountPlanFeatureFlagEnabled() ||
             (isNewUpgradeAccountPlanFeatureFlagEnabled() && showPlanRow)) {
            return IndexPath(row: row - 1, section: section)
        }
        return IndexPath(row: row, section: section)
    }
}
